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


-- security helpers
create or replace function public.has_child_access(_child_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.children c
    where c.id = _child_id and c.created_by = auth.uid()
  )
  or exists (
    select 1 from public.care_teams ct
    where ct.child_id = _child_id and ct.user_id = auth.uid() and ct.status = 'active'
  );
$$;

create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.admin_users au
    where au.id = auth.uid() and au.status = 'active'
  );
$$;

-- enable RLS for core business and admin tables
alter table public.users enable row level security;
alter table public.children enable row level security;
alter table public.children_medical enable row level security;
alter table public.children_memory enable row level security;
alter table public.children_profiles enable row level security;
alter table public.care_teams enable row level security;
alter table public.child_snapshots enable row level security;
alter table public.assessments enable row level security;
alter table public.training_plans enable row level security;
alter table public.training_sessions enable row level security;
alter table public.teaching_schedules enable row level security;
alter table public.behavior_records enable row level security;
alter table public.life_records enable row level security;
alter table public.reports enable row level security;
alter table public.notifications enable row level security;
alter table public.conversations enable row level security;
alter table public.chat_messages enable row level security;

alter table public.admin_users enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.admin_prompts enable row level security;
alter table public.announcements enable row level security;
alter table public.feedbacks enable row level security;
alter table public.admin_events enable row level security;
alter table public.coupons enable row level security;
alter table public.push_tasks enable row level security;
alter table public.campaigns enable row level security;

-- users policies
create policy users_select_self on public.users
for select using (id = auth.uid());

create policy users_insert_self on public.users
for insert with check (id = auth.uid());

create policy users_update_self on public.users
for update using (id = auth.uid()) with check (id = auth.uid());

-- children policies
create policy children_owner_rw on public.children
for all using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy children_team_read on public.children
for select using (public.has_child_access(id));

-- generic child-id table policies
create policy children_medical_access on public.children_medical
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy children_memory_access on public.children_memory
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy children_profiles_access on public.children_profiles
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy child_snapshots_access on public.child_snapshots
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy assessments_access on public.assessments
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy training_plans_access on public.training_plans
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy training_sessions_access on public.training_sessions
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy behavior_records_access on public.behavior_records
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy life_records_access on public.life_records
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy reports_access on public.reports
for all using (public.has_child_access(child_id)) with check (public.has_child_access(child_id));

create policy notifications_select_access on public.notifications
for select using (to_user_id = auth.uid() or from_user_id = auth.uid());

create policy notifications_insert_access on public.notifications
for insert with check (from_user_id = auth.uid());

create policy notifications_update_access on public.notifications
for update using (to_user_id = auth.uid() or from_user_id = auth.uid())
with check (to_user_id = auth.uid() or from_user_id = auth.uid());

create policy care_teams_owner_read on public.care_teams
for select using (
  user_id = auth.uid()
  or exists (
    select 1 from public.children c where c.id = care_teams.child_id and c.created_by = auth.uid()
  )
);

create policy care_teams_owner_insert on public.care_teams
for insert with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.children c where c.id = care_teams.child_id and c.created_by = auth.uid()
  )
);

create policy care_teams_owner_update on public.care_teams
for update using (
  exists (
    select 1 from public.children c where c.id = care_teams.child_id and c.created_by = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.children c where c.id = care_teams.child_id and c.created_by = auth.uid()
  )
);

create policy conversations_owner_access on public.conversations
for all using (user_id = auth.uid() and public.has_child_access(child_id))
with check (user_id = auth.uid() and public.has_child_access(child_id));

create policy chat_messages_owner_access on public.chat_messages
for all using (user_id = auth.uid() and public.has_child_access(child_id))
with check (user_id = auth.uid() and public.has_child_access(child_id));

-- admin policies
create policy admin_users_self_or_admin on public.admin_users
for select using (id = auth.uid() or public.is_admin_user());

create policy admin_users_admin_write on public.admin_users
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy admin_audit_admin_access on public.admin_audit_logs
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy admin_prompts_admin_access on public.admin_prompts
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy announcements_admin_access on public.announcements
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy feedbacks_admin_access on public.feedbacks
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy admin_events_admin_access on public.admin_events
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy coupons_admin_access on public.coupons
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy push_tasks_admin_access on public.push_tasks
for all using (public.is_admin_user()) with check (public.is_admin_user());

create policy campaigns_admin_access on public.campaigns
for all using (public.is_admin_user()) with check (public.is_admin_user());


-- transactional outbox writeback helper
create function public.finalize_writeback(
  p_request_id uuid,
  p_actor_user_id uuid,
  p_child_id uuid,
  p_action_name varchar,
  p_affected_tables jsonb,
  p_event_source_table varchar,
  p_event_type varchar,
  p_priority_level varchar,
  p_target_snapshot_type varchar,
  p_payload jsonb,
  p_db_write_status varchar,
  p_outbox_write_status varchar,
  p_final_status varchar,
  p_latency_ms integer,
  p_error_code varchar,
  p_error_message text
)
returns void
language plpgsql
security definer
as $$
declare
  v_event_id uuid;
begin
  insert into public.snapshot_refresh_events (
    request_id,
    child_id,
    event_source_table,
    event_type,
    priority_level,
    target_snapshot_type,
    payload,
    status
  ) values (
    p_request_id,
    p_child_id,
    p_event_source_table,
    p_event_type,
    p_priority_level,
    p_target_snapshot_type,
    coalesce(p_payload, '{}'::jsonb),
    'pending'
  ) returning id into v_event_id;

  insert into public.operation_logs (
    request_id,
    actor_user_id,
    child_id,
    action_name,
    affected_tables,
    db_write_status,
    outbox_write_status,
    final_status,
    latency_ms,
    error_code,
    error_message
  ) values (
    p_request_id,
    p_actor_user_id,
    p_child_id,
    p_action_name,
    coalesce(p_affected_tables, '[]'::jsonb),
    p_db_write_status,
    p_outbox_write_status,
    p_final_status,
    p_latency_ms,
    p_error_code,
    p_error_message
  );
end;
$$;

-- conversation consistency helper
create function public.sync_conversation_after_message()
returns trigger
language plpgsql
security definer
as $$
begin
  update public.conversations
  set
    last_message_at = new.created_at,
    message_count = message_count + 1,
    updated_at = now()
  where id = new.conversation_id;

  return new;
end;
$$;

drop trigger if exists trg_chat_message_update_conversation on public.chat_messages;
create trigger trg_chat_message_update_conversation
after insert on public.chat_messages
for each row
execute function public.sync_conversation_after_message();

commit;
