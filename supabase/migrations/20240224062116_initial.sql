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
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

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

create table interviews (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  completed_at timestamp with time zone
);

create table interview_messages (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid references interviews not null,
  role varchar not null, -- "user", "assistant", etc.
  content varchar not null,
  metadata jsonb not null default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);


-- Storage Buckets
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
