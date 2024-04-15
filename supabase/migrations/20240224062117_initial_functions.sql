-- trigger on votes, checks if round_id is active,
-- checks if user has enough votes to allocate,
-- updates user votes_balance (user has enough votes if the absolute value of "allocation"
-- is less than or equal to vote value, the absolute value is subtracted from the user's votes_balance)
create or replace function check_votes()
returns trigger as $$
begin
  if not exists (select 1 from rounds where id = new.round_id and active = true and voting_enabled = true) then
    raise exception 'Round is not active or does not allow votes';
  end if;

  if new.allocation = 0 then
    raise exception 'Allocation must be non-zero';
  end if;

  if abs(new.allocation) > (select votes_balance from users where id = new.user_id) then
    raise exception 'User does not have enough votes';
  end if;

  update users set votes_balance = votes_balance - abs(new.allocation) where id = new.user_id;
  return new;
end;
$$ language plpgsql;

create trigger check_votes_trigger
before insert on votes
for each row
execute function check_votes();

create or replace function get_profile()
returns profiles as $$
  select * from profiles where user_id = auth.uid();
$$ language sql stable;

create or replace function create_match(profile_id uuid) returns void as $$
  insert into matches (profile_id, matched_profile_id)
  values ((select id from profiles where user_id = auth.uid()), profile_id);
$$ language sql;

create or replace function get_unmatched_profiles()
returns setof profiles as $$
  select * from profiles where (user_id != auth.uid() or user_id is null) and id not in (select matched_profile_id from matches where profile_id = (select id from profiles where user_id = auth.uid()) or matched_profile_id = (select id from profiles where user_id = auth.uid()));
$$ language sql stable;

-- function that returns jsonb of match_id and a profile field containing the matching profile for the match for the logged in user
create or replace function get_matches()
returns setof jsonb as $$
  select jsonb_build_object('id', m.id, 'profile', jsonb_build_object('id', p.id, 'first_name', p.first_name, 'birth_date', p.birth_date
    , 'gender', p.gender, 'location', p.location, 'display_location', p.display_location, 'biographical_data', p.biographical_data, 'preferences',
    p.preferences, 'photo_keys', p.photo_keys, 'blocks', p.blocks))
  from matches m
  join profiles p on ((p.user_id is null or p.user_id != auth.uid()) and (m.profile_id = p.id or m.matched_profile_id = p.id))
  where m.match_accepted_at is not null and (m.profile_id = (select id from profiles where user_id = auth.uid()) or m.matched_profile_id = (select id from profiles where user_id = auth.uid()));
$$ language sql stable;

create or replace function get_likes()
returns setof jsonb as $$
  select jsonb_build_object('id', m.id, 'profile', jsonb_build_object('id', p.id, 'first_name', p.first_name, 'birth_date', p.birth_date
    , 'gender', p.gender, 'location', p.location, 'display_location', p.display_location, 'biographical_data', p.biographical_data, 'preferences', p.preferences, 'photo_keys', p.photo_keys, 'blocks', p.blocks))
  from matches m
  join profiles p on ((p.user_id is null or p.user_id != auth.uid()) and (m.profile_id = p.id or m.matched_profile_id = p.id))
  where m.match_accepted_at is null and m.match_rejected_at is null and m.matched_profile_id = (select id from profiles where user_id = auth.uid());
$$ language sql stable;

create or replace function send_message(match_id uuid, message text)
returns void as $$
  insert into messages (match_id, sender_id, message)
  values (match_id, (select id from profiles where user_id = auth.uid()), message);
$$ language sql;

create or replace function get_pending_bot_matches()
returns setof matches as $$
  select m.* from matches m left join profiles p on m.matched_profile_id = p.id where p.user_id is null and m.match_accepted_at is null and m.match_rejected_at is null;
$$ language sql stable;

create or replace function sanitize_available_photos()
returns trigger as $$
begin
  if new.available_photos is null or jsonb_array_length(new.available_photos) = 0 then
    return new;
  end if;

  new.available_photos = (
    select jsonb_agg(
      case
        when (new.available_photos->>((i::int) - 1))::jsonb ? 'description' then
          (new.available_photos->>((i::int) - 1))::jsonb
        else
          jsonb_build_object(
            'key', (new.available_photos->>((i::int) - 1))::jsonb->>'key',
            'description', (old.available_photos->>((i::int) - 1))::jsonb->>'description'
          )
      end
    )
    from jsonb_array_elements(new.available_photos) with ordinality as arr(elem, i)
  );

  if exists (
    select 1
    from jsonb_array_elements(new.available_photos) as photo
    where photo->>'description' is null
  ) then
    insert into job (name, data)
      values ('processPhotos', jsonb_build_object('profileId', new.id));
  end if;

  return new;
end;
$$ language plpgsql;

create trigger update_profiles_available_photos_trigger
before update on profiles
for each row
execute function sanitize_available_photos();

-- returns the currently matching profile (matching_profile_id) for the logged in user, if not set, chooses one from saved_profiles, if no saved profiles, chooses a random profile, and sets matching_profile_id
create or replace function get_matching_profile()
returns profiles as $$
declare
  matching_profile profiles;
begin
  select * into matching_profile from profiles where id = (select matching_profile_id from users where id = auth.uid());
  if matching_profile.id is null then
    select * into matching_profile from profiles where id = (select profile_id from saved_profiles where user_id = auth.uid() order by created_at desc limit 1);
    if matching_profile.id is null then
      select * into matching_profile from profiles where id in (select id from profiles where user_id != auth.uid() or user_id is null order by random() limit 1);
      insert into saved_profiles (user_id, profile_id) values (auth.uid(), matching_profile.id);
    end if;
    update users set matching_profile_id = matching_profile.id where id = auth.uid();
  end if;
  return matching_profile;
end;
$$ language plpgsql;

create or replace function get_contestant_profiles()
returns setof profiles as $$
  select * from profiles where (user_id != auth.uid() or user_id is null) and id != (select id from get_matching_profile());
$$ language sql;

-- returns the match for the given profiles, creates one if it does not exist
create or replace function get_match(profile_1 uuid, profile_2 uuid)
returns matches_with_votes as $$
declare
  match matches_with_votes;
begin
  select * into match from matches_with_votes where (profile_id = profile_1 and matched_profile_id = profile_2) or (profile_id = profile_2 and matched_profile_id = profile_1);
  if match is null then
    insert into matches (profile_id, matched_profile_id) values (profile_1, profile_2);
    select * into match from matches_with_votes where profile_id = profile_1 and matched_profile_id = profile_2;
  end if;
  return match;
end;
$$ language plpgsql;

create function active_interview_for_profile(profile_id uuid) returns interviews as $$
  select * from interviews where profile_id = $1 and completed_at is null limit 1;
$$ language sql stable;

create function active_interview() returns interviews as $$
  select * from interviews where profile_id = (select id from get_profile()) and completed_at is null limit 1;
$$ language sql stable;
