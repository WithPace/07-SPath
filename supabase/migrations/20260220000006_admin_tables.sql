-- ============================================
-- 管理后台域（9 张表，与终端用户完全隔离）
-- ============================================

-- admin_users — 管理员账号
CREATE TABLE admin_users (
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
CREATE UNIQUE INDEX idx_admin_email ON admin_users (email);
-- admin_audit_logs — 管理员操作审计日志
CREATE TABLE admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES admin_users(id),
  action VARCHAR NOT NULL,
  target_type VARCHAR NOT NULL,
  target_id VARCHAR,
  details JSONB,
  ip VARCHAR,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_admin_time ON admin_audit_logs (admin_id, created_at DESC);
CREATE INDEX idx_audit_target ON admin_audit_logs (target_type, target_id);
-- admin_prompts — AI Prompt 版本管理
CREATE TABLE admin_prompts (
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
CREATE INDEX idx_prompts_role_status ON admin_prompts (role, status);
-- announcements — 系统公告
CREATE TABLE announcements (
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
CREATE INDEX idx_announce_status_time ON announcements (status, publish_at DESC)
  WHERE status = 'published';
-- feedbacks — 用户反馈
CREATE TABLE feedbacks (
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
CREATE INDEX idx_feedback_status ON feedbacks (status, created_at DESC)
  WHERE status IN ('pending', 'processing');
CREATE INDEX idx_feedback_user ON feedbacks (user_id, created_at DESC);
-- admin_events — 运营日历
CREATE TABLE admin_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  date DATE NOT NULL,
  type VARCHAR NOT NULL DEFAULT 'meeting'
    CHECK (type IN ('release', 'campaign', 'holiday', 'meeting')),
  description TEXT,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- coupons — 优惠券
CREATE TABLE coupons (
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
CREATE UNIQUE INDEX idx_coupon_code ON coupons (code);
-- push_tasks — 推送任务
CREATE TABLE push_tasks (
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
CREATE INDEX idx_push_status_time ON push_tasks (status, scheduled_at)
  WHERE status IN ('draft', 'scheduled');
-- campaigns — 运营活动
CREATE TABLE campaigns (
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
CREATE INDEX idx_campaign_status_time ON campaigns (status, start_at)
  WHERE status = 'active';
-- updated_at 自动更新触发器
CREATE OR REPLACE FUNCTION update_admin_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_admin_users_updated BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
CREATE TRIGGER trg_admin_prompts_updated BEFORE UPDATE ON admin_prompts FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
CREATE TRIGGER trg_announcements_updated BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
CREATE TRIGGER trg_feedbacks_updated BEFORE UPDATE ON feedbacks FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
CREATE TRIGGER trg_push_tasks_updated BEFORE UPDATE ON push_tasks FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
CREATE TRIGGER trg_campaigns_updated BEFORE UPDATE ON campaigns FOR EACH ROW EXECUTE FUNCTION update_admin_updated_at();
