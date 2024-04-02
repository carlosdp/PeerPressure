create extension postgis with schema extensions;

create type gender as enum ('male', 'female', 'non-binary', 'other');

create table rounds(
  id uuid primary key default gen_random_uuid(),
  name varchar not null,
  voting_enabled boolean not null default false,
  join_balance integer not null default 0, -- number of votes user starts with if they join while round is active
  active boolean not null default false,
  end_time timestamp with time zone not null
);

-- trigger that ensures only one round is active at a time
create or replace function ensure_one_active_round()
returns trigger as $$
begin
  if new.active then
    update rounds set active = false where id != new.id;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger ensure_one_active_round_trigger
before update on rounds
for each row
execute function ensure_one_active_round();

create table users (
  id uuid primary key references auth.users,
  display_name varchar not null default 'Player',
  votes_balance integer not null default 0,
  matching_profile_id uuid references profiles
);

-- trigger create users when auth.user is created
create or replace function create_user()
returns trigger as $$
begin
  insert into public.users (id, votes_balance)
  select new.id, coalesce((select join_balance from public.rounds where active = true), 0);
  return new;
end;
$$ language plpgsql security definer;

create trigger create_user_trigger
after insert on auth.users
for each row
execute function create_user();

create table profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users unique, -- null if this is a synthetic profile
  first_name varchar not null,
  birth_date date not null,
  gender gender not null,
  location geography(point) not null,
  display_location varchar not null,
  biographical_data jsonb not null default '{}',
  preferences jsonb not null default '{}',
  photo_keys jsonb not null default '[]',
  available_photos jsonb not null default '[]',
  blocks jsonb not null default '[]',
  builder_conversation_data jsonb not null default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table saved_profiles (
  primary key (user_id, profile_id),
  user_id uuid references auth.users not null,
  profile_id uuid references profiles not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table matches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles not null,
  matched_profile_id uuid references profiles not null,
  match_accepted_at timestamp with time zone,
  match_rejected_at timestamp with time zone,
  data jsonb not null default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create unique index idx_unique_matches_profile_ids
  on matches (least(profile_id, matched_profile_id), greatest(profile_id, matched_profile_id));

create table messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references matches not null,
  sender_id uuid references profiles not null,
  message text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter publication supabase_realtime add table messages;

create table votes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  round_id uuid references rounds not null,
  match_id uuid references matches not null,
  allocation integer not null, -- votes allocated, can be positive or negative
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- view that returns matches with total votes for each match
create or replace view matches_with_votes as
select m.*, coalesce(sum(v.allocation), 0) as total_votes
from matches m
left join votes v on m.id = v.match_id
group by m.id;

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

insert into storage.buckets (id, name) values ('photos', 'photos');
create policy "Users can upload photos for their profile"
on storage.objects for insert with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1]::uuid = (select id from profiles where user_id = auth.uid())
);
create policy "Authenticated users can read photos"
on storage.objects for select using ( bucket_id = 'photos' and auth.role() = 'authenticated' );

insert into storage.buckets (id, name) values ('videos', 'videos');
create policy "Users can upload videos for their profile"
on storage.objects for insert with check (
    bucket_id = 'videos'
    and (storage.foldername(name))[1]::uuid = (select id from profiles where user_id = auth.uid())
);

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
