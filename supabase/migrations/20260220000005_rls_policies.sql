-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE children_medical ENABLE ROW LEVEL SECURITY;
ALTER TABLE children_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE children_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE care_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
-- Helper function: check if user is in care_team for a child
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
-- Helper function: check if user is parent of a child
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
-- users: users can read/update their own record
CREATE POLICY "users_select_own" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (id = auth.uid());
-- children: parent can CRUD, care_team can read
CREATE POLICY "children_select" ON children FOR SELECT
  USING (is_care_team_member(id));
CREATE POLICY "children_insert" ON children FOR INSERT
  WITH CHECK (created_by = auth.uid());
CREATE POLICY "children_update" ON children FOR UPDATE
  USING (is_parent_of(id));
-- children_medical: parent can CRUD, care_team can read
CREATE POLICY "medical_select" ON children_medical FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "medical_insert" ON children_medical FOR INSERT
  WITH CHECK (is_parent_of(child_id));
CREATE POLICY "medical_update" ON children_medical FOR UPDATE
  USING (is_parent_of(child_id));
-- children_memory: parent can CRUD, care_team can read
CREATE POLICY "memory_select" ON children_memory FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "memory_insert" ON children_memory FOR INSERT
  WITH CHECK (is_parent_of(child_id));
CREATE POLICY "memory_update" ON children_memory FOR UPDATE
  USING (is_care_team_member(child_id));
-- children_profiles: care_team can read, parent/doctor can write
CREATE POLICY "profiles_select" ON children_profiles FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "profiles_insert" ON children_profiles FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
-- care_teams: members can see their own teams
CREATE POLICY "care_teams_select" ON care_teams FOR SELECT
  USING (user_id = auth.uid() OR is_parent_of(child_id));
CREATE POLICY "care_teams_insert" ON care_teams FOR INSERT
  WITH CHECK (user_id = auth.uid() OR is_parent_of(child_id));
CREATE POLICY "care_teams_update" ON care_teams FOR UPDATE
  USING (is_parent_of(child_id));
-- child_snapshots: care_team can read
CREATE POLICY "snapshots_select" ON child_snapshots FOR SELECT
  USING (is_care_team_member(child_id));
-- assessments: care_team can read, parent/doctor can write
CREATE POLICY "assessments_select" ON assessments FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "assessments_insert" ON assessments FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
-- training_plans: care_team can read
CREATE POLICY "plans_select" ON training_plans FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "plans_insert" ON training_plans FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
CREATE POLICY "plans_update" ON training_plans FOR UPDATE
  USING (is_care_team_member(child_id));
-- training_sessions: care_team can read
CREATE POLICY "sessions_select" ON training_sessions FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "sessions_insert" ON training_sessions FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
-- behavior_records: care_team can read/write
CREATE POLICY "behavior_select" ON behavior_records FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "behavior_insert" ON behavior_records FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
-- life_records: parent can CRUD
CREATE POLICY "life_select" ON life_records FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "life_insert" ON life_records FOR INSERT
  WITH CHECK (is_parent_of(child_id));
-- reports: care_team can read
CREATE POLICY "reports_select" ON reports FOR SELECT
  USING (is_care_team_member(child_id));
CREATE POLICY "reports_insert" ON reports FOR INSERT
  WITH CHECK (is_care_team_member(child_id));
-- notifications: recipient can read
CREATE POLICY "notif_select" ON notifications FOR SELECT
  USING (to_user_id = auth.uid());
CREATE POLICY "notif_insert" ON notifications FOR INSERT
  WITH CHECK (from_user_id = auth.uid());
CREATE POLICY "notif_update" ON notifications FOR UPDATE
  USING (to_user_id = auth.uid());
-- conversations: owner can CRUD
CREATE POLICY "conv_select" ON conversations FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "conv_insert" ON conversations FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "conv_update" ON conversations FOR UPDATE
  USING (user_id = auth.uid());
-- chat_messages: conversation owner can read/write
CREATE POLICY "msg_select" ON chat_messages FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "msg_insert" ON chat_messages FOR INSERT
  WITH CHECK (user_id = auth.uid());
