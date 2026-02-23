-- ==================== assessments ====================
CREATE TABLE assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  result JSONB,
  risk_level VARCHAR(20),
  recommendations JSONB,
  assessed_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_assessments_child_type ON assessments(child_id, type, created_at DESC);
-- ==================== training_plans ====================
CREATE TABLE training_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  goals JSONB DEFAULT '[]'::jsonb,
  strategies JSONB DEFAULT '[]'::jsonb,
  schedule JSONB,
  difficulty_level VARCHAR(20),
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft','active','completed','archived')),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_plans_child_status ON training_plans(child_id, status) WHERE status = 'active';
-- ==================== training_sessions ====================
CREATE TABLE training_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES training_plans(id),
  target_skill VARCHAR(100),
  execution_summary TEXT,
  prompt_level VARCHAR(30),
  success_rate DECIMAL(5,2),
  duration_minutes INTEGER,
  notes TEXT,
  input_type VARCHAR(10) DEFAULT 'text',
  voice_url VARCHAR(500),
  ai_structured JSONB,
  feedback JSONB,
  recorded_by UUID REFERENCES users(id),
  session_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_sessions_child_date ON training_sessions(child_id, session_date DESC);
CREATE INDEX idx_sessions_plan_id ON training_sessions(plan_id);
-- ==================== behavior_records ====================
CREATE TABLE behavior_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  behavior_type VARCHAR(50),
  antecedent TEXT,
  behavior TEXT,
  consequence TEXT,
  behavior_function VARCHAR(30),
  intensity INTEGER CHECK (intensity BETWEEN 1 AND 5),
  severity VARCHAR(20),
  duration_minutes INTEGER,
  context JSONB,
  recorded_by UUID REFERENCES users(id),
  occurred_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_behavior_child_time ON behavior_records(child_id, occurred_at DESC);
CREATE INDEX idx_behavior_severity ON behavior_records(child_id, severity)
  WHERE severity = 'urgent';
-- ==================== life_records ====================
CREATE TABLE life_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL CHECK (type IN ('emotion','sleep','diet','behavior_event','milestone')),
  content JSONB,
  summary TEXT,
  media_urls JSONB DEFAULT '[]'::jsonb,
  recorded_by UUID REFERENCES users(id),
  occurred_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_life_child_type_time ON life_records(child_id, type, occurred_at DESC);
-- ==================== reports ====================
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL,
  title VARCHAR(200),
  content JSONB,
  summary TEXT,
  file_url VARCHAR(500),
  period VARCHAR(10),
  generated_by VARCHAR(20) DEFAULT 'AI',
  visible_to JSONB DEFAULT '["parent"]'::jsonb,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- ==================== notifications ====================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES children(id) ON DELETE CASCADE,
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID NOT NULL REFERENCES users(id),
  type VARCHAR(30) NOT NULL,
  title VARCHAR(200),
  content TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_notif_to_user_read ON notifications(to_user_id, is_read, created_at DESC);
CREATE TRIGGER trg_training_plans_updated_at BEFORE UPDATE ON training_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
