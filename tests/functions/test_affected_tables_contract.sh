#!/usr/bin/env bash
set -euo pipefail

check_action_tables() {
  local file="$1"
  local action="$2"
  shift 2

  if ! grep -q "actionName: \"${action}\"" "$file"; then
    echo "missing action ${action} in ${file}" >&2
    exit 1
  fi

  for table in "$@"; do
    if ! grep -q "affectedTables: .*${table}" "$file"; then
      echo "missing table ${table} in affectedTables for ${action} (${file})" >&2
      exit 1
    fi
  done
}

check_action_tables \
  supabase/functions/chat-casual/index.ts \
  chat_casual_reply \
  chat_messages children_memory snapshot_refresh_events operation_logs

check_action_tables \
  supabase/functions/assessment/index.ts \
  assessment_generate \
  assessments children_profiles chat_messages snapshot_refresh_events operation_logs

check_action_tables \
  supabase/functions/training/index.ts \
  training_generate \
  training_plans children_memory chat_messages snapshot_refresh_events operation_logs

check_action_tables \
  supabase/functions/training-advice/index.ts \
  training_advice_generate \
  training_plans children_memory chat_messages snapshot_refresh_events operation_logs

check_action_tables \
  supabase/functions/training-record/index.ts \
  training_record_create \
  training_sessions children_profiles chat_messages snapshot_refresh_events operation_logs

check_action_tables \
  supabase/functions/dashboard/index.ts \
  dashboard_generate \
  training_sessions assessments training_plans chat_messages snapshot_refresh_events operation_logs

echo "affectedTables contract checks pass"
