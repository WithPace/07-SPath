-- ============================================
-- RLS 修复补丁 v2：彻底解决 care_teams 无限递归
-- 核心原则：care_teams 的 RLS 策略绝不引用 care_teams 自身
-- ============================================

-- ========== 1. 彻底重建 care_teams RLS 策略 ==========
DROP POLICY IF EXISTS "care_teams_select" ON care_teams;
DROP POLICY IF EXISTS "care_teams_insert" ON care_teams;
DROP POLICY IF EXISTS "care_teams_update" ON care_teams;
DROP POLICY IF EXISTS "care_teams_delete" ON care_teams;
-- SELECT: 用户只能看到自己参与的 care_team 记录
-- 家长要看团队全部成员，通过前端先查自己的记录拿到 child_id，再用 child_id 过滤
-- 但 RLS 层面只需要 user_id = auth.uid() 就够了，因为家长查团队时
-- 前端会用 .eq("child_id", xxx) 过滤，而家长自己的记录一定能查到
CREATE POLICY "care_teams_select" ON care_teams FOR SELECT
  USING (user_id = auth.uid());
-- INSERT: 只能创建自己的 care_team 记录（邀请成员通过 RPC 函数）
CREATE POLICY "care_teams_insert" ON care_teams FOR INSERT
  WITH CHECK (user_id = auth.uid());
-- UPDATE: 只能更新自己的记录（家长修改他人权限通过 RPC 函数）
CREATE POLICY "care_teams_update" ON care_teams FOR UPDATE
  USING (user_id = auth.uid());
-- DELETE: 只能删除自己的记录（家长移除他人通过 RPC 函数）
CREATE POLICY "care_teams_delete" ON care_teams FOR DELETE
  USING (user_id = auth.uid());
-- ========== 2. 创建家长管理团队的 RPC 函数（SECURITY DEFINER 绕过 RLS）==========

-- 家长查看团队全部成员
CREATE OR REPLACE FUNCTION get_care_team(p_child_id UUID)
RETURNS SETOF care_teams AS $$
BEGIN
  -- 验证调用者是该孩子的 care_team 成员
  IF NOT EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id AND user_id = auth.uid() AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
    SELECT * FROM care_teams
    WHERE child_id = p_child_id AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 家长邀请成员
CREATE OR REPLACE FUNCTION invite_care_team_member(
  p_child_id UUID,
  p_user_id UUID,
  p_role VARCHAR,
  p_permissions JSONB
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  -- 验证调用者是该孩子的家长
  IF NOT EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id AND user_id = auth.uid() AND role = 'parent' AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Only parent can invite members';
  END IF;

  INSERT INTO care_teams (child_id, user_id, role, permissions, invited_by, status)
  VALUES (p_child_id, p_user_id, p_role, p_permissions, auth.uid(), 'active')
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 家长更新成员权限
CREATE OR REPLACE FUNCTION update_care_team_permissions(
  p_child_id UUID,
  p_user_id UUID,
  p_permissions JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  -- 验证调用者是该孩子的家长
  IF NOT EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id AND user_id = auth.uid() AND role = 'parent' AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Only parent can update permissions';
  END IF;

  UPDATE care_teams SET permissions = p_permissions
  WHERE child_id = p_child_id AND user_id = p_user_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 家长移除成员
CREATE OR REPLACE FUNCTION remove_care_team_member(
  p_child_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- 验证调用者是该孩子的家长
  IF NOT EXISTS (
    SELECT 1 FROM care_teams
    WHERE child_id = p_child_id AND user_id = auth.uid() AND role = 'parent' AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Only parent can remove members';
  END IF;

  -- 不能移除自己（家长）
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot remove yourself';
  END IF;

  DELETE FROM care_teams
  WHERE child_id = p_child_id AND user_id = p_user_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ========== 3. 验证 is_care_team_member / is_parent_of 函数 owner ==========
-- 确保这两个函数以 postgres (superuser) 身份执行，绕过 care_teams RLS
-- SECURITY DEFINER 函数以 owner 身份执行，postgres 是 superuser 不受 RLS 限制

-- 重新创建确保 owner 正确（CREATE OR REPLACE 保持 owner 不变）
-- 如果之前是 supabase_admin 创建的，需要 ALTER OWNER
DO $$ BEGIN
  ALTER FUNCTION is_care_team_member(UUID) OWNER TO postgres;
  ALTER FUNCTION is_parent_of(UUID) OWNER TO postgres;
EXCEPTION WHEN OTHERS THEN
  -- 忽略错误（可能已经是 postgres）
  NULL;
END $$;
