-- destructive rebuild skeleton
begin;

-- core tables (drop order honors fks)
drop table if exists public.chat_messages cascade;
drop table if exists public.conversations cascade;
drop table if exists public.operation_logs cascade;
drop table if exists public.snapshot_refresh_events cascade;

create extension if not exists pgcrypto;

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null,
  user_id uuid not null,
  title varchar not null default '新对话',
  last_message_at timestamptz not null default now(),
  message_count integer not null default 0,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  child_id uuid not null,
  user_id uuid not null,
  role varchar not null check (role in ('user','assistant')),
  content text not null,
  media_urls jsonb,
  cards_json jsonb,
  model_used varchar,
  edge_function varchar,
  created_at timestamptz not null default now()
);

create table public.operation_logs (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  actor_user_id uuid,
  child_id uuid,
  action_name varchar not null,
  affected_tables jsonb not null default '[]'::jsonb,
  db_write_status varchar not null,
  outbox_write_status varchar not null,
  final_status varchar not null,
  latency_ms integer,
  error_code varchar,
  error_message text,
  created_at timestamptz not null default now()
);

create table public.snapshot_refresh_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  child_id uuid,
  event_source_table varchar not null,
  event_type varchar not null,
  priority_level varchar not null,
  target_snapshot_type varchar not null,
  payload jsonb not null default '{}'::jsonb,
  status varchar not null default 'pending',
  retry_count integer not null default 0,
  next_retry_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

commit;
