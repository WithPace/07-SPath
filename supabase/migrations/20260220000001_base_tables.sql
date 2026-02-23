-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- ==================== users ====================
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone VARCHAR(20),
  name VARCHAR(100),
  avatar_url VARCHAR(500),
  roles JSONB DEFAULT '["parent"]'::jsonb,
  vip_level VARCHAR(20) DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- ==================== children ====================
CREATE TABLE children (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nickname VARCHAR(50) NOT NULL,
  real_name VARCHAR(50),
  gender VARCHAR(10),
  birth_date DATE,
  avatar_url VARCHAR(500),
  creator_relation VARCHAR(50),
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_children_created_by ON children(created_by);
-- ==================== children_medical ====================
CREATE TABLE children_medical (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  diagnosis_level VARCHAR(20),
  diagnosis_type VARCHAR(50),
  diagnosis_date DATE,
  diagnosis_institution VARCHAR(200),
  cert_file_url VARCHAR(500),
  severity VARCHAR(20),
  comorbidities JSONB DEFAULT '[]'::jsonb,
  medication_status VARCHAR(20) DEFAULT 'unknown',
  medication_names VARCHAR(200),
  intervention_history JSONB DEFAULT '[]'::jsonb,
  follow_up_records JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- ==================== children_memory ====================
CREATE TABLE children_memory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE UNIQUE,
  nickname VARCHAR(50),
  personality JSONB DEFAULT '[]'::jsonb,
  preferences JSONB DEFAULT '[]'::jsonb,
  effective_strategies JSONB DEFAULT '[]'::jsonb,
  triggers JSONB DEFAULT '[]'::jsonb,
  milestones JSONB DEFAULT '[]'::jsonb,
  communication_style TEXT,
  sensory_profile JSONB,
  social_patterns JSONB,
  routine_preferences JSONB,
  reinforcers JSONB DEFAULT '[]'::jsonb,
  avoidances JSONB DEFAULT '[]'::jsonb,
  family_context JSONB,
  current_focus TEXT,
  care_notes TEXT,
  medical_notes TEXT,
  special_notes TEXT,
  last_interaction_summary TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX idx_memory_child_id ON children_memory(child_id);
-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_children_updated_at BEFORE UPDATE ON children
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_children_medical_updated_at BEFORE UPDATE ON children_medical
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_children_memory_updated_at BEFORE UPDATE ON children_memory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
