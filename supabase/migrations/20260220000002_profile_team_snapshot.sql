-- ==================== children_profiles ====================
CREATE TABLE children_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  version INTEGER NOT NULL DEFAULT 1,
  domain_levels JSONB NOT NULL DEFAULT '{}'::jsonb,
  overall_summary TEXT,
  assessed_by UUID REFERENCES users(id),
  assessed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_profiles_child_version ON children_profiles(child_id, version DESC);
-- ==================== care_teams ====================
CREATE TABLE care_teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('parent', 'doctor', 'teacher')),
  permissions JSONB DEFAULT '{
    "profile": "rw", "assessment": "rw", "training": "rw",
    "life": "rw", "behavior": "rw", "report": "rw",
    "medical": "rw", "snapshot": "r"
  }'::jsonb,
  invited_by UUID REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, child_id, role)
);
CREATE INDEX idx_care_teams_user_child ON care_teams(user_id, child_id);
CREATE INDEX idx_care_teams_child_id ON care_teams(child_id);
-- ==================== child_snapshots ====================
CREATE TABLE child_snapshots (
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  snapshot_type VARCHAR(20) NOT NULL CHECK (snapshot_type IN ('short_term', 'long_term')),
  snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  refreshed_at TIMESTAMPTZ DEFAULT now(),
  is_stale BOOLEAN DEFAULT false,
  PRIMARY KEY (child_id, snapshot_type)
);
CREATE TRIGGER trg_care_teams_updated_at BEFORE UPDATE ON care_teams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
