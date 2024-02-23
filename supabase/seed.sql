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
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table matches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles not null,
  matched_profile_id uuid references profiles not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references matches not null,
  sender_id uuid references profiles not null,
  message text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

insert into storage.buckets (id, name) values ('photos', 'photos');
