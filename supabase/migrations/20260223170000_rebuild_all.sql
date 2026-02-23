-- destructive rebuild (full schema freeze 2026-02-23)
begin;

create extension if not exists pgcrypto;

-- drop in dependency-safe order
drop table if exists public.campaigns cascade;
drop table if exists public.push_tasks cascade;
drop table if exists public.coupons cascade;
drop table if exists public.admin_events cascade;
drop table if exists public.feedbacks cascade;
drop table if exists public.announcements cascade;
drop table if exists public.admin_prompts cascade;
drop table if exists public.admin_audit_logs cascade;
drop table if exists public.admin_users cascade;

drop table if exists public.snapshot_refresh_logs cascade;
drop table if exists public.operation_logs cascade;
drop table if exists public.snapshot_refresh_events cascade;

drop table if exists public.chat_messages cascade;
drop table if exists public.conversations cascade;

drop table if exists public.org_members cascade;
drop table if exists public.organizations cascade;

drop table if exists public.notifications cascade;
drop table if exists public.reports cascade;

drop table if exists public.life_records cascade;
drop table if exists public.behavior_records cascade;
drop table if exists public.teaching_schedules cascade;
drop table if exists public.training_sessions cascade;
drop table if exists public.training_plans cascade;
drop table if exists public.assessments cascade;

drop table if exists public.child_snapshots cascade;
drop table if exists public.care_teams cascade;
drop table if exists public.children_profiles cascade;
drop table if exists public.children_memory cascade;
drop table if exists public.children_medical cascade;
drop table if exists public.children cascade;
drop table if exists public.users cascade;

create table public.users (
  id uuid primary key,
  phone varchar,
  name varchar,
  avatar_url varchar,
  roles jsonb not null default '[]'::jsonb,
  vip_level varchar,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  nickname varchar not null,
  real_name varchar,
  gender varchar,
  birth_date date,
  avatar_url varchar,
  creator_relation varchar,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.children_medical (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  diagnosis_level varchar,
  diagnosis_type varchar,
  diagnosis_date date,
  diagnosis_institution varchar,
  cert_file_url varchar,
  severity varchar,
  comorbidities jsonb,
  medication_status varchar,
  medication_names varchar,
  intervention_history jsonb,
  follow_up_records jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.children_memory (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null unique references public.children(id) on delete cascade,
  nickname varchar,
  personality jsonb,
  preferences jsonb,
  effective_strategies jsonb,
  triggers jsonb,
  milestones jsonb,
  communication_style text,
  sensory_profile jsonb,
  social_patterns jsonb,
  routine_preferences jsonb,
  reinforcers jsonb,
  avoidances jsonb,
  family_context jsonb,
  current_focus text,
  care_notes text,
  medical_notes text,
  special_notes text,
  last_interaction_summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.children_profiles (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  version integer not null,
  domain_levels jsonb not null,
  overall_summary text,
  assessed_by uuid references public.users(id),
  assessed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.care_teams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  child_id uuid not null references public.children(id) on delete cascade,
  role varchar not null,
  permissions jsonb not null default '{}'::jsonb,
  invited_by uuid references public.users(id),
  status varchar not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, child_id, role)
);

create table public.child_snapshots (
  child_id uuid not null references public.children(id) on delete cascade,
  snapshot_type varchar(20) not null,
  snapshot jsonb not null default '{}'::jsonb,
  refreshed_at timestamptz,
  is_stale boolean not null default false,
  primary key (child_id, snapshot_type)
);

create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  type varchar not null,
  result jsonb not null,
  risk_level varchar,
  recommendations jsonb,
  assessed_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create table public.training_plans (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  title varchar not null,
  goals jsonb,
  strategies jsonb,
  schedule jsonb,
  difficulty_level varchar,
  status varchar not null default 'draft',
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.training_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  plan_id uuid references public.training_plans(id) on delete set null,
  target_skill varchar,
  execution_summary text,
  prompt_level varchar,
  success_rate decimal,
  duration_minutes integer,
  notes text,
  input_type varchar not null default 'text',
  voice_url varchar,
  ai_structured jsonb,
  feedback jsonb,
  recorded_by uuid references public.users(id),
  session_date date,
  created_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name varchar not null,
  type varchar,
  address text,
  contact_phone varchar,
  qualifications jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.org_members (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.users(id),
  org_role varchar not null,
  joined_at timestamptz,
  status varchar not null default 'active',
  created_at timestamptz not null default now()
);

create table public.teaching_schedules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.organizations(id) on delete cascade,
  teacher_id uuid references public.users(id),
  child_id uuid references public.children(id) on delete cascade,
  course_type varchar,
  start_time timestamptz,
  end_time timestamptz,
  recurrence_rule jsonb,
  location varchar,
  status varchar not null default 'scheduled',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.behavior_records (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  behavior_type varchar,
  antecedent text,
  behavior text,
  consequence text,
  behavior_function varchar,
  intensity integer,
  severity varchar,
  duration_minutes integer,
  context jsonb,
  recorded_by uuid references public.users(id),
  occurred_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.life_records (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  type varchar not null,
  content jsonb,
  summary text,
  media_urls jsonb,
  recorded_by uuid references public.users(id),
  occurred_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  type varchar not null,
  title varchar,
  content jsonb,
  summary text,
  file_url varchar,
  period varchar,
  generated_by varchar,
  visible_to jsonb,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade,
  from_user_id uuid references public.users(id),
  to_user_id uuid references public.users(id),
  type varchar,
  title varchar,
  content text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  user_id uuid not null references public.users(id),
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
  child_id uuid not null references public.children(id) on delete cascade,
  user_id uuid not null references public.users(id),
  role varchar not null check (role in ('user', 'assistant')),
  content text not null,
  media_urls jsonb,
  cards_json jsonb,
  model_used varchar,
  edge_function varchar,
  created_at timestamptz not null default now()
);

create table public.snapshot_refresh_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  child_id uuid references public.children(id) on delete set null,
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

create table public.operation_logs (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  actor_user_id uuid references public.users(id),
  child_id uuid references public.children(id) on delete set null,
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

create table public.snapshot_refresh_logs (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.snapshot_refresh_events(id) on delete set null,
  child_id uuid references public.children(id) on delete set null,
  snapshot_type varchar,
  started_at timestamptz,
  finished_at timestamptz,
  duration_ms integer,
  status varchar,
  checksum_before varchar,
  checksum_after varchar,
  error_code varchar,
  created_at timestamptz not null default now()
);

create table public.admin_users (
  id uuid primary key default gen_random_uuid(),
  email varchar not null unique,
  name varchar not null,
  role varchar not null,
  status varchar not null default 'active',
  totp_secret varchar,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.admin_users(id) on delete set null,
  action varchar not null,
  target_type varchar,
  target_id varchar,
  details jsonb,
  ip varchar,
  created_at timestamptz not null default now()
);

create table public.admin_prompts (
  id uuid primary key default gen_random_uuid(),
  role varchar not null,
  content text not null,
  version integer not null,
  status varchar not null default 'draft',
  versions jsonb,
  ab_config jsonb,
  updated_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title varchar not null,
  content text not null,
  status varchar not null default 'draft',
  target_audience jsonb,
  publish_at timestamptz,
  expire_at timestamptz,
  created_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  content text not null,
  status varchar not null default 'pending',
  tags jsonb,
  replies jsonb,
  assigned_to uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.admin_events (
  id uuid primary key default gen_random_uuid(),
  title varchar not null,
  date date not null,
  type varchar,
  description text,
  created_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code varchar not null unique,
  type varchar not null,
  value jsonb,
  valid_from timestamptz,
  valid_to timestamptz,
  usage_limit integer not null default 0,
  used_count integer not null default 0,
  target_audience jsonb,
  created_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.push_tasks (
  id uuid primary key default gen_random_uuid(),
  title varchar not null,
  content text not null,
  target_type varchar not null,
  target_filter jsonb,
  target_user_ids jsonb,
  status varchar not null default 'draft',
  scheduled_at timestamptz,
  sent_at timestamptz,
  stats jsonb,
  created_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  name varchar not null,
  type varchar not null,
  rules jsonb,
  start_at timestamptz,
  end_at timestamptz,
  status varchar not null default 'draft',
  stats jsonb,
  created_by uuid references public.admin_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- indexes
create index idx_children_created_by on public.children (created_by);
create unique index idx_care_teams_user_child on public.care_teams (user_id, child_id, role);
create index idx_care_teams_child_id on public.care_teams (child_id);
create index idx_sessions_child_date on public.training_sessions (child_id, session_date desc);
create index idx_sessions_plan_id on public.training_sessions (plan_id);
create index idx_life_child_type_time on public.life_records (child_id, type, occurred_at desc);
create index idx_behavior_child_time on public.behavior_records (child_id, occurred_at desc);
create index idx_behavior_severity on public.behavior_records (child_id, severity) where severity = 'urgent';
create index idx_assessments_child_type on public.assessments (child_id, type, created_at desc);
create index idx_profiles_child_version on public.children_profiles (child_id, version desc);
create unique index idx_memory_child_id on public.children_memory (child_id);
create index idx_chat_conversation_time on public.chat_messages (conversation_id, created_at desc);
create index idx_conv_user_child_time on public.conversations (user_id, child_id, last_message_at desc) where is_deleted = false;
create index idx_notif_to_user_read on public.notifications (to_user_id, is_read, created_at desc);
create index idx_plans_child_status on public.training_plans (child_id, status) where status = 'active';
create index idx_schedule_teacher_time on public.teaching_schedules (teacher_id, start_time);
create index idx_schedule_org_time on public.teaching_schedules (org_id, start_time);
create index idx_sre_status_priority on public.snapshot_refresh_events (status, priority_level, created_at) where status = 'pending';
create index idx_oplog_request_id on public.operation_logs (request_id);

create index idx_users_roles on public.users using gin (roles);
create index idx_care_teams_permissions on public.care_teams using gin (permissions);

create unique index idx_admin_email on public.admin_users (email);
create index idx_audit_admin_time on public.admin_audit_logs (admin_id, created_at desc);
create index idx_audit_target on public.admin_audit_logs (target_type, target_id);
create index idx_prompts_role_status on public.admin_prompts (role, status);
create index idx_announce_status_time on public.announcements (status, publish_at desc) where status = 'published';
create index idx_feedback_status on public.feedbacks (status, created_at desc) where status in ('pending', 'processing');
create index idx_feedback_user on public.feedbacks (user_id, created_at desc);
create unique index idx_coupon_code on public.coupons (code);
create index idx_push_status_time on public.push_tasks (status, scheduled_at) where status in ('draft', 'scheduled');
create index idx_campaign_status_time on public.campaigns (status, start_at) where status = 'active';

commit;
