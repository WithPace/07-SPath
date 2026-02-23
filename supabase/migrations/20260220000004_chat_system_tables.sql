-- ==================== conversations ====================
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200),
  last_message_at TIMESTAMPTZ DEFAULT now(),
  message_count INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_conv_user_child_time ON conversations(user_id, child_id, last_message_at DESC)
  WHERE is_deleted = false;
-- ==================== chat_messages ====================
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
CREATE INDEX idx_chat_conversation_time ON chat_messages(conversation_id, created_at DESC);
-- ==================== snapshot_refresh_events ====================
CREATE TABLE snapshot_refresh_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
CREATE INDEX idx_sre_status_priority ON snapshot_refresh_events(status, priority_level, created_at)
  WHERE status = 'pending';
-- ==================== operation_logs ====================
CREATE TABLE operation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
CREATE INDEX idx_oplog_request_id ON operation_logs(request_id);
-- ==================== snapshot_refresh_logs ====================
CREATE TABLE snapshot_refresh_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
CREATE TRIGGER trg_conversations_updated_at BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_sre_updated_at BEFORE UPDATE ON snapshot_refresh_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
