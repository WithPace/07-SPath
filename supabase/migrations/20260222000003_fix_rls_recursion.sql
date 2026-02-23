-- ============================================
-- RLS 修复补丁：解决 care_teams 无限递归 + 补缺失策略
-- ============================================

-- ========== 1. 修复 care_teams RLS 无限递归 ==========
-- 问题：care_teams_select 调用 is_parent_of() → 查 care_teams → 触发 RLS → 再调 is_parent_of() → 无限递归
-- 方案：删除旧策略，用不依赖函数的直接条件重建

DROP POLICY IF EXISTS "care_teams_select" ON care_teams;
DROP POLICY IF EXISTS "care_teams_insert" ON care_teams;
DROP POLICY IF EXISTS "care_teams_update" ON care_teams;
-- SELECT: 自己的记录 + 同一个孩子的家长可以看所有成员
CREATE POLICY "care_teams_select" ON care_teams FOR SELECT
  USING (
    user_id = auth.uid()
    OR child_id IN (
      SELECT child_id FROM care_teams
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );
-- INSERT: 自己加入 或 已是该孩子的家长
CREATE POLICY "care_teams_insert" ON care_teams FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR child_id IN (
      SELECT child_id FROM care_teams
      WHERE user_id = auth.uid() AND role = 'parent' AND status = 'active'
    )
  );
-- UPDATE: 只有该孩子的家长可以修改（如权限调整）
CREATE POLICY "care_teams_update" ON care_teams FOR UPDATE
  USING (
    child_id IN (
      SELECT child_id FROM care_teams
      WHERE user_id = auth.uid() AND role = 'parent' AND status = 'active'
    )
  );
-- DELETE: 家长可以移除成员
CREATE POLICY "care_teams_delete" ON care_teams FOR DELETE
  USING (
    user_id = auth.uid()
    OR child_id IN (
      SELECT child_id FROM care_teams
      WHERE user_id = auth.uid() AND role = 'parent' AND status = 'active'
    )
  );
-- ========== 2. child_snapshots 补 INSERT/UPDATE 策略 ==========
-- 前端 createChild 需要 INSERT，Edge Functions 用 service client 不受影响
CREATE POLICY "snapshots_insert" ON child_snapshots FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
CREATE POLICY "snapshots_update" ON child_snapshots FOR UPDATE
  USING (is_care_team_member(child_id));
-- ========== 3. 前端 createChild 流程需要的 INSERT 策略修复 ==========
-- children_memory: 当前只允许 is_parent_of，但创建孩子时 care_teams 还没建好
-- 需要允许 created_by 用户插入（创建流程中 care_teams 尚未存在）
DROP POLICY IF EXISTS "memory_insert" ON children_memory;
CREATE POLICY "memory_insert" ON children_memory FOR INSERT
  WITH CHECK (
    is_parent_of(child_id)
    OR child_id IN (SELECT id FROM children WHERE created_by = auth.uid())
  );
-- children_profiles: 同理
DROP POLICY IF EXISTS "profiles_insert" ON children_profiles;
CREATE POLICY "profiles_insert" ON children_profiles FOR INSERT
  WITH CHECK (
    is_care_team_member(child_id)
    OR child_id IN (SELECT id FROM children WHERE created_by = auth.uid())
  );
-- child_snapshots: 同理，创建时 care_teams 可能还没建好
DROP POLICY IF EXISTS "snapshots_insert" ON child_snapshots;
CREATE POLICY "snapshots_insert" ON child_snapshots FOR INSERT
  WITH CHECK (
    is_care_team_member(child_id)
    OR child_id IN (SELECT id FROM children WHERE created_by = auth.uid())
  );
-- children_medical: 同理
DROP POLICY IF EXISTS "medical_insert" ON children_medical;
CREATE POLICY "medical_insert" ON children_medical FOR INSERT
  WITH CHECK (
    is_parent_of(child_id)
    OR child_id IN (SELECT id FROM children WHERE created_by = auth.uid())
  );
-- ========== 4. 系统表保护 ==========
-- snapshot_refresh_events: 启用 RLS，仅 service role 可写
ALTER TABLE snapshot_refresh_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshot_refresh_logs ENABLE ROW LEVEL SECURITY;
-- 管理员可读
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'sre_admin_read') THEN
    CREATE POLICY "sre_admin_read" ON snapshot_refresh_events FOR SELECT USING (is_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'srl_admin_read') THEN
    CREATE POLICY "srl_admin_read" ON snapshot_refresh_logs FOR SELECT USING (is_admin());
  END IF;
END $$;
-- ========== 5. users 表补充：care_team 成员可查看彼此基本信息 ==========
-- 当前只有 users_select_own，导致前端无法显示团队成员名字
CREATE POLICY "users_select_team" ON users FOR SELECT
  USING (
    id IN (
      SELECT ct2.user_id FROM care_teams ct1
      JOIN care_teams ct2 ON ct1.child_id = ct2.child_id
      WHERE ct1.user_id = auth.uid() AND ct1.status = 'active' AND ct2.status = 'active'
    )
  );
