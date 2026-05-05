-- SoberLife MVP schema v1
-- DB-01: foundational tables for onboarding, sobriety tracking, AI chat, and social-ready links

create extension if not exists "pgcrypto";

-- Users profile
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  apple_id text unique not null,
  name text,
  avatar_url text,
  sobriety_start_date timestamptz,
  daily_alcohol_cost numeric(12,2) check (daily_alcohol_cost >= 0),
  created_at timestamptz not null default now()
);

-- Sobriety periods (history includes relapses and restarts)
create table if not exists public.sobriety_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  start_date timestamptz not null,
  end_date timestamptz,
  is_current boolean not null default true,
  created_at timestamptz not null default now(),
  check (end_date is null or end_date >= start_date)
);

-- Guarantee only one active period per user
create unique index if not exists sobriety_records_one_current_idx
  on public.sobriety_records (user_id)
  where is_current = true;

create index if not exists sobriety_records_user_created_idx
  on public.sobriety_records (user_id, created_at desc);

-- Achievements unlock history
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null,
  unlocked_at timestamptz not null default now(),
  unique (user_id, type)
);

create index if not exists achievements_user_unlocked_idx
  on public.achievements (user_id, unlocked_at desc);

-- Journal entries and mood tracking
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  content text,
  mood text check (mood in ('great', 'good', 'okay', 'struggling', 'crisis')),
  created_at timestamptz not null default now()
);

create index if not exists journal_entries_user_created_idx
  on public.journal_entries (user_id, created_at desc);

-- Trigger records for analysis and AI context
create table if not exists public.triggers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  trigger_type text check (trigger_type in ('place', 'person', 'emotion', 'event')),
  description text,
  intensity integer check (intensity between 1 and 10),
  created_at timestamptz not null default now()
);

create index if not exists triggers_user_created_idx
  on public.triggers (user_id, created_at desc);

-- AI conversation snapshots
create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  messages jsonb not null default '[]'::jsonb,
  conversation_type text not null check (conversation_type in ('sos', 'daily', 'analysis', 'chat')),
  created_at timestamptz not null default now()
);

create index if not exists ai_conversations_user_created_idx
  on public.ai_conversations (user_id, created_at desc);

-- Social-ready friendship links (future feature, included for compatibility)
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  friend_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  check (user_id <> friend_id),
  unique (user_id, friend_id)
);

create index if not exists friendships_user_status_idx
  on public.friendships (user_id, status);
