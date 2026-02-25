#!/usr/bin/env bash
set -euo pipefail

check_writeback_metadata() {
  local file="$1"
  local action="$2"
  local source_table="$3"
  local event_type="$4"
  local snapshot_type="$5"

  grep -q "actionName: \"${action}\"" "$file"
  grep -q "eventSourceTable: \"${source_table}\"" "$file"
  grep -q "eventType: \"${event_type}\"" "$file"
  grep -q "targetSnapshotType: \"${snapshot_type}\"" "$file"
}

check_writeback_metadata \
  supabase/functions/chat-casual/index.ts \
  chat_casual_reply \
  chat_messages \
  insert \
  both

check_writeback_metadata \
  supabase/functions/assessment/index.ts \
  assessment_generate \
  children_profiles \
  insert \
  both

check_writeback_metadata \
  supabase/functions/training/index.ts \
  training_generate \
  training_plans \
  insert \
  both

check_writeback_metadata \
  supabase/functions/training-advice/index.ts \
  training_advice_generate \
  training_plans \
  insert \
  both

check_writeback_metadata \
  supabase/functions/training-record/index.ts \
  training_record_create \
  children_profiles \
  insert \
  both

check_writeback_metadata \
  supabase/functions/dashboard/index.ts \
  dashboard_generate \
  training_sessions \
  read \
  short_term

echo "writeback metadata contract checks pass"
