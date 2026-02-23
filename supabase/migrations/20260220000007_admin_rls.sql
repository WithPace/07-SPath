-- ============================================
-- 管理后台 RLS 策略
-- 基于 admin_users.role 控制访问
-- ============================================

-- 辅助函数：获取当前管理员角色
CREATE OR REPLACE FUNCTION get_admin_role()
RETURNS VARCHAR AS $$
  SELECT role FROM admin_users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;
-- 辅助函数：是否为管理员
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND status = 'active');
$$ LANGUAGE sql SECURITY DEFINER STABLE;
-- admin_users
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "super_admin_full_access" ON admin_users
  FOR ALL USING (get_admin_role() = 'super_admin');
CREATE POLICY "admin_read_self" ON admin_users
  FOR SELECT USING (id = auth.uid());
-- admin_audit_logs
ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_audit" ON admin_audit_logs
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_insert_audit" ON admin_audit_logs
  FOR INSERT WITH CHECK (is_admin());
-- admin_prompts
ALTER TABLE admin_prompts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_prompts" ON admin_prompts
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_prompts" ON admin_prompts
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- announcements
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_announcements" ON announcements
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_announcements" ON announcements
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- feedbacks
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_feedbacks" ON feedbacks
  FOR SELECT USING (is_admin());
CREATE POLICY "cs_write_assigned_feedbacks" ON feedbacks
  FOR UPDATE USING (
    get_admin_role() IN ('super_admin', 'operator')
    OR (get_admin_role() = 'cs_agent' AND assigned_to = auth.uid())
  );
CREATE POLICY "admin_insert_feedbacks" ON feedbacks
  FOR INSERT WITH CHECK (true);
-- 终端用户也可提交反馈

-- admin_events
ALTER TABLE admin_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_events" ON admin_events
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_events" ON admin_events
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- coupons
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_coupons" ON coupons
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_coupons" ON coupons
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- push_tasks
ALTER TABLE push_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_push" ON push_tasks
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_push" ON push_tasks
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- campaigns
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_read_campaigns" ON campaigns
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_write_campaigns" ON campaigns
  FOR ALL USING (get_admin_role() IN ('super_admin', 'operator'));
-- 管理员对终端用户数据的只读访问
CREATE POLICY "admin_read_users" ON users
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_read_children" ON children
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_read_chat_messages" ON chat_messages
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_read_operation_logs" ON operation_logs
  FOR SELECT USING (is_admin());
