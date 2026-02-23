-- 修复 children 表 SELECT RLS 策略
-- 问题：创建孩子时 step 1 做 INSERT + .select().single()，
-- 但此时 care_teams 还没插入，is_care_team_member(id) 返回 false，
-- 导致 SELECT 被 RLS 拒绝，前端拿不到刚插入的记录。
-- 解决：增加 created_by = auth.uid() 条件，让创建者始终能看到自己创建的孩子。

DROP POLICY IF EXISTS "children_select" ON children;
CREATE POLICY "children_select" ON children FOR SELECT
  USING (
    created_by = auth.uid()
    OR is_care_team_member(id)
  );
