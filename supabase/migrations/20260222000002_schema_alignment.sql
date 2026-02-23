-- ============================================
-- 全面 Schema 对齐补丁
-- 远程数据库（旧版手动创建）→ 本地迁移文件定义
-- ============================================

-- ========== 1. users 表：id 改为引用 auth.users ==========
-- 远程: id uuid DEFAULT gen_random_uuid(), phone NOT NULL
-- 本地: id uuid REFERENCES auth.users(id), phone 可空
-- 注意：不改 PK 引用（已有数据），只加缺失字段
-- phone 已有 NOT NULL 约束，保持不变

-- ========== 2. children 表：加缺失字段 ==========
-- 远程: name(NOT NULL), gender, birth_date, avatar_url, created_by, created_at, updated_at
-- 本地: nickname(NOT NULL), real_name, gender, birth_date, avatar_url, creator_relation, created_by, created_at, updated_at
ALTER TABLE children ADD COLUMN IF NOT EXISTS nickname VARCHAR(50);
ALTER TABLE children ADD COLUMN IF NOT EXISTS real_name VARCHAR(50);
ALTER TABLE children ADD COLUMN IF NOT EXISTS creator_relation VARCHAR(50);
-- 把现有 name 数据复制到 nickname
UPDATE children SET nickname = name WHERE nickname IS NULL;
-- ========== 3. children_medical 表：加缺失字段 ==========
-- 远程缺少: diagnosis_level, cert_file_url, medication_status, medication_names, intervention_history
ALTER TABLE children_medical ADD COLUMN IF NOT EXISTS diagnosis_level VARCHAR(20);
ALTER TABLE children_medical ADD COLUMN IF NOT EXISTS cert_file_url VARCHAR(500);
ALTER TABLE children_medical ADD COLUMN IF NOT EXISTS medication_status VARCHAR(20) DEFAULT 'unknown';
ALTER TABLE children_medical ADD COLUMN IF NOT EXISTS medication_names VARCHAR(200);
ALTER TABLE children_medical ADD COLUMN IF NOT EXISTS intervention_history JSONB DEFAULT '[]'::jsonb;
-- ========== 4. children_memory 表：加缺失字段 ==========
-- 远程缺少: nickname, current_focus, care_notes
-- 远程 personality 是 text，本地是 jsonb — 加新列不改旧列
ALTER TABLE children_memory ADD COLUMN IF NOT EXISTS nickname VARCHAR(50);
ALTER TABLE children_memory ADD COLUMN IF NOT EXISTS current_focus TEXT;
ALTER TABLE children_memory ADD COLUMN IF NOT EXISTS care_notes TEXT;
-- ========== 5. children_profiles 表：加 domain_levels ==========
-- 远程用分域字段(social/communication/cognition/self_care/behavior/play)
-- 本地用 domain_levels JSONB
ALTER TABLE children_profiles ADD COLUMN IF NOT EXISTS domain_levels JSONB NOT NULL DEFAULT '{}'::jsonb;
-- 迁移旧数据到 domain_levels
UPDATE children_profiles SET domain_levels = jsonb_build_object(
  'social', COALESCE(social, '{}'::jsonb),
  'communication', COALESCE(communication, '{}'::jsonb),
  'cognition', COALESCE(cognition, '{}'::jsonb),
  'self_care', COALESCE(self_care, '{}'::jsonb),
  'behavior', COALESCE(behavior, '{}'::jsonb),
  'play', COALESCE(play, '{}'::jsonb)
) WHERE domain_levels = '{}'::jsonb;
-- ========== 6. child_snapshots 表：加缺失字段 ==========
ALTER TABLE child_snapshots ADD COLUMN IF NOT EXISTS is_stale BOOLEAN DEFAULT false;
-- ========== 7. behavior_records 表：加缺失字段 ==========
-- 远程缺少: behavior_type, behavior_function, intensity
-- 远程有 function_hypothesis，本地用 behavior_function
ALTER TABLE behavior_records ADD COLUMN IF NOT EXISTS behavior_type VARCHAR(50);
ALTER TABLE behavior_records ADD COLUMN IF NOT EXISTS behavior_function VARCHAR(30);
ALTER TABLE behavior_records ADD COLUMN IF NOT EXISTS intensity INTEGER;
-- ========== 8. training_sessions 表：加缺失字段 ==========
-- 远程缺少: input_type, voice_url, ai_structured
ALTER TABLE training_sessions ADD COLUMN IF NOT EXISTS input_type VARCHAR(10) DEFAULT 'text';
ALTER TABLE training_sessions ADD COLUMN IF NOT EXISTS voice_url VARCHAR(500);
ALTER TABLE training_sessions ADD COLUMN IF NOT EXISTS ai_structured JSONB;
-- ========== 9. 创建缺失的表 ==========

-- conversations
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200),
  last_message_at TIMESTAMPTZ DEFAULT now(),
  message_count INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_conv_user_child_time ON conversations(user_id, child_id, last_message_at DESC)
  WHERE is_deleted = false;
-- chat_messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT,
  media_urls JSONB,
  cards_json JSONB,
  model_used VARCHAR(50),
  edge_function VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chat_conversation_time ON chat_messages(conversation_id, created_at DESC);
-- snapshot_refresh_events
CREATE TABLE IF NOT EXISTS snapshot_refresh_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  event_source_table VARCHAR(50) NOT NULL,
  event_type VARCHAR(30) NOT NULL,
  priority_level VARCHAR(5) NOT NULL CHECK (priority_level IN ('S1','S2','S3')),
  target_snapshot_type VARCHAR(20) NOT NULL CHECK (target_snapshot_type IN ('short_term','long_term','both')),
  payload JSONB DEFAULT '{}'::jsonb,
  status VARCHAR(20) DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  next_retry_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_sre_status_priority ON snapshot_refresh_events(status, priority_level, created_at)
  WHERE status = 'pending';
-- operation_logs
CREATE TABLE IF NOT EXISTS operation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL,
  actor_user_id UUID REFERENCES users(id),
  child_id UUID REFERENCES children(id),
  action_name VARCHAR(100) NOT NULL,
  affected_tables JSONB DEFAULT '[]'::jsonb,
  db_write_status VARCHAR(20) DEFAULT 'success',
  outbox_write_status VARCHAR(20) DEFAULT 'success',
  final_status VARCHAR(20) DEFAULT 'completed',
  latency_ms INTEGER,
  error_code VARCHAR(50),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_oplog_request_id ON operation_logs(request_id);
-- snapshot_refresh_logs
CREATE TABLE IF NOT EXISTS snapshot_refresh_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES snapshot_refresh_events(id),
  child_id UUID NOT NULL REFERENCES children(id),
  snapshot_type VARCHAR(20) NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now(),
  finished_at TIMESTAMPTZ,
  duration_ms INTEGER,
  status VARCHAR(20) DEFAULT 'success',
  checksum_before VARCHAR(64),
  checksum_after VARCHAR(64),
  error_code VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- ========== 10. 管理后台表 ==========

-- admin_users
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR NOT NULL UNIQUE,
  password_hash VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  role VARCHAR NOT NULL DEFAULT 'operator'
    CHECK (role IN ('super_admin', 'operator', 'cs_agent', 'analyst')),
  status VARCHAR NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'disabled')),
  totp_secret VARCHAR,
  totp_enabled BOOLEAN NOT NULL DEFAULT false,
  last_login_at TIMESTAMPTZ,
  login_fail_count INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- admin_audit_logs
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES admin_users(id),
  action VARCHAR NOT NULL,
  target_type VARCHAR NOT NULL,
  target_id VARCHAR,
  details JSONB,
  ip VARCHAR,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_admin_time ON admin_audit_logs (admin_id, created_at DESC);
-- admin_prompts
CREATE TABLE IF NOT EXISTS admin_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR NOT NULL,
  content TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  status VARCHAR NOT NULL DEFAULT 'draft'
    CHECK (status IN ('active', 'draft', 'archived')),
  versions JSONB NOT NULL DEFAULT '[]'::jsonb,
  ab_config JSONB,
  updated_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- announcements
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  content TEXT NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'published', 'archived')),
  target_audience JSONB,
  publish_at TIMESTAMPTZ,
  expire_at TIMESTAMPTZ,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- feedbacks
CREATE TABLE IF NOT EXISTS feedbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'replied', 'closed')),
  tags JSONB DEFAULT '[]'::jsonb,
  priority INTEGER DEFAULT 0,
  ai_summary VARCHAR,
  replies JSONB DEFAULT '[]'::jsonb,
  assigned_to UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- admin_events
CREATE TABLE IF NOT EXISTS admin_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  date DATE NOT NULL,
  type VARCHAR NOT NULL DEFAULT 'meeting'
    CHECK (type IN ('release', 'campaign', 'holiday', 'meeting')),
  description TEXT,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- coupons
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR NOT NULL UNIQUE,
  type VARCHAR NOT NULL CHECK (type IN ('discount', 'fixed', 'trial')),
  value NUMERIC NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_to TIMESTAMPTZ NOT NULL,
  usage_limit INTEGER NOT NULL DEFAULT 0,
  used_count INTEGER NOT NULL DEFAULT 0,
  target_audience JSONB,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- push_tasks
CREATE TABLE IF NOT EXISTS push_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  content TEXT NOT NULL,
  target_type VARCHAR NOT NULL DEFAULT 'all'
    CHECK (target_type IN ('all', 'segment', 'individual')),
  target_filter JSONB,
  target_user_ids UUID[],
  status VARCHAR NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  stats JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- campaigns
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  type VARCHAR NOT NULL CHECK (type IN ('free_trial', 'invite_reward', 'holiday', 'discount')),
  rules JSONB NOT NULL DEFAULT '{}'::jsonb,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'paused', 'ended')),
  stats JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- ========== 11. updated_at 触发器 ==========
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_conversations_updated_at') THEN
    CREATE TRIGGER trg_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_sre_updated_at') THEN
    CREATE TRIGGER trg_sre_updated_at BEFORE UPDATE ON snapshot_refresh_events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;
-- 管理后台触发器
CREATE OR REPLACE FUNCTION update_admin_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_admin_users_updated') THEN
    CREATE TRIGGER trg_admin_users_updated BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_admin_prompts_updated') THEN
    CREATE TRIGGER trg_admin_prompts_updated BEFORE UPDATE ON admin_prompts FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_announcements_updated') THEN
    CREATE TRIGGER trg_announcements_updated BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_feedbacks_updated') THEN
    CREATE TRIGGER trg_feedbacks_updated BEFORE UPDATE ON feedbacks FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_push_tasks_updated') THEN
    CREATE TRIGGER trg_push_tasks_updated BEFORE UPDATE ON push_tasks FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_campaigns_updated') THEN
    CREATE TRIGGER trg_campaigns_updated BEFORE UPDATE ON campaigns FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
  END IF;
END $$;
-- ========== 12. RLS 策略（对话表 + 系统表 + 管理后台表） ==========

-- 对话表 RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION is_care_team_member(p_child_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id
      AND user_id = auth.uid()
      AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION is_parent_of(p_child_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id
      AND user_id = auth.uid()
      AND role = 'parent'
      AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- conversations RLS
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conv_select') THEN
    CREATE POLICY "conv_select" ON conversations FOR SELECT USING (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conv_insert') THEN
    CREATE POLICY "conv_insert" ON conversations FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conv_update') THEN
    CREATE POLICY "conv_update" ON conversations FOR UPDATE USING (user_id = auth.uid());
  END IF;
END $$;
-- chat_messages RLS
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'msg_select') THEN
    CREATE POLICY "msg_select" ON chat_messages FOR SELECT USING (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'msg_insert') THEN
    CREATE POLICY "msg_insert" ON chat_messages FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
-- 管理后台 RLS
CREATE OR REPLACE FUNCTION get_admin_role()
RETURNS VARCHAR AS $$
  SELECT role FROM admin_users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND status = 'active');
$$ LANGUAGE sql SECURITY DEFINER STABLE;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- 管理后台 RLS 策略（简化版，用 DO 块避免重复）
DO $$ BEGIN
  -- admin_users
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'super_admin_full_access') THEN
    CREATE POLICY "super_admin_full_access" ON admin_users FOR ALL USING (get_admin_role() = 'super_admin');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_self') THEN
    CREATE POLICY "admin_read_self" ON admin_users FOR SELECT USING (id = auth.uid());
  END IF;

  -- admin_audit_logs
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_audit') THEN
    CREATE POLICY "admin_read_audit" ON admin_audit_logs FOR SELECT USING (is_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_insert_audit') THEN
    CREATE POLICY "admin_insert_audit" ON admin_audit_logs FOR INSERT WITH CHECK (is_admin());
  END IF;

  -- admin_prompts
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_prompts') THEN
    CREATE POLICY "admin_read_prompts" ON admin_prompts FOR SELECT USING (is_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_write_prompts') THEN
    CREATE POLICY "admin_write_prompts" ON admin_prompts FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
  END IF;

  -- announcements
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_announcements') THEN
    CREATE POLICY "admin_read_announcements" ON announcements FOR SELECT USING (is_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_write_announcements') THEN
    CREATE POLICY "admin_write_announcements" ON announcements FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
  END IF;

  -- feedbacks
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_feedbacks') THEN
    CREATE POLICY "admin_read_feedbacks" ON feedbacks FOR SELECT USING (is_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_insert_feedbacks') THEN
    CREATE POLICY "admin_insert_feedbacks" ON feedbacks FOR INSERT WITH CHECK (true);
  END IF;

  -- operation_logs (管理员只读)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'admin_read_operation_logs') THEN
    ALTER TABLE operation_logs ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "admin_read_operation_logs" ON operation_logs FOR SELECT USING (is_admin());
  END IF;
END $$;
