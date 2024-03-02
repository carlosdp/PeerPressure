create extension postgis with schema extensions;

create type gender as enum ('male', 'female', 'non-binary', 'other');

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
  profile_photo_key varchar,
  photo_keys jsonb not null default '[]',
  available_photo_keys jsonb not null default '[]',
  blocks jsonb not null default '[]',
  builder_conversation_data jsonb not null default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table matches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles not null,
  matched_profile_id uuid references profiles not null,
  is_match boolean not null,
  match_accepted_at timestamp with time zone,
  match_rejected_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references matches not null,
  sender_id uuid references profiles not null,
  message text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter publication supabase_realtime add table messages;

insert into storage.buckets (id, name) values ('photos', 'photos');
create policy "Users can upload photos for their profile"
on storage.objects for insert with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1]::uuid = (select id from profiles where user_id = auth.uid())
);
create policy "Authenticated users can read photos"
on storage.objects for select using ( bucket_id = 'photos' and auth.role() = 'authenticated' );

create or replace function get_profile()
returns profiles as $$
  select * from profiles where user_id = auth.uid();
$$ language sql stable;

create or replace function create_match(profile_id uuid, is_match boolean) returns void as $$
  insert into matches (profile_id, matched_profile_id, is_match)
  values ((select id from profiles where user_id = auth.uid()), profile_id, is_match);
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
    p.preferences, 'profile_photo_key', p.profile_photo_key, 'photo_keys', p.photo_keys, 'blocks', p.blocks))
  from matches m
  join profiles p on ((p.user_id is null or p.user_id != auth.uid()) and (m.profile_id = p.id or m.matched_profile_id = p.id))
  where m.is_match = true and m.match_accepted_at is not null and (m.profile_id = (select id from profiles where user_id = auth.uid()) or m.matched_profile_id = (select id from profiles where user_id = auth.uid()));
$$ language sql stable;

create or replace function get_likes()
returns setof jsonb as $$
  select jsonb_build_object('id', m.id, 'profile', jsonb_build_object('id', p.id, 'first_name', p.first_name, 'birth_date', p.birth_date
    , 'gender', p.gender, 'location', p.location, 'display_location', p.display_location, 'biographical_data', p.biographical_data, 'preferences', p.preferences))
  from matches m
  join profiles p on ((p.user_id is null or p.user_id != auth.uid()) and (m.profile_id = p.id or m.matched_profile_id = p.id))
  where m.is_match = true and m.match_accepted_at is null and m.match_rejected_at is null and m.matched_profile_id = (select id from profiles where user_id = auth.uid());
$$ language sql stable;

create or replace function send_message(match_id uuid, message text)
returns void as $$
  insert into messages (match_id, sender_id, message)
  values (match_id, (select id from profiles where user_id = auth.uid()), message);
$$ language sql;

create or replace function get_pending_bot_matches()
returns setof matches as $$
  select m.* from matches m left join profiles p on m.matched_profile_id = p.id where p.user_id is null and m.match_accepted_at is null and m.match_rejected_at is null and m.is_match = true;
$$ language sql stable;
