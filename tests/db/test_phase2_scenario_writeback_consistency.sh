#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

weekly="tests/e2e/test_phase2_parent_weekly_journey_live.sh"
followup="tests/e2e/test_phase2_parent_dashboard_followup_live.sh"

test -f "$weekly" || fail "missing weekly scenario script"
test -f "$followup" || fail "missing dashboard followup scenario script"

# Weekly scenario must cover full phase2 module chain and verify writeback tables.
rg -q 'assessment_generate' "$weekly" || fail "weekly scenario missing assessment action check"
rg -q 'training_advice_generate' "$weekly" || fail "weekly scenario missing training_advice action check"
rg -q 'training_generate' "$weekly" || fail "weekly scenario missing training action check"
rg -q 'training_record_create' "$weekly" || fail "weekly scenario missing training_record action check"
rg -q 'dashboard_generate' "$weekly" || fail "weekly scenario missing dashboard action check"

rg -q '/rest/v1/assessments\?select=id' "$weekly" || fail "weekly scenario missing assessments writeback check"
rg -q '/rest/v1/training_plans\?select=id' "$weekly" || fail "weekly scenario missing training_plans writeback check"
rg -q '/rest/v1/training_sessions\?select=id' "$weekly" || fail "weekly scenario missing training_sessions writeback check"
rg -q '/rest/v1/children_memory\?select=current_focus' "$weekly" || fail "weekly scenario missing children_memory writeback check"
rg -q 'cards_json' "$weekly" || fail "weekly scenario missing dashboard cards check"

# Follow-up scenario must validate dashboard writeback consistency after training flow.
rg -q 'training_generate' "$followup" || fail "followup scenario missing training action check"
rg -q 'training_record_create' "$followup" || fail "followup scenario missing training_record action check"
rg -q 'dashboard_generate' "$followup" || fail "followup scenario missing dashboard action check"
rg -q 'affected_tables' "$followup" || fail "followup scenario missing affected_tables check"
rg -q 'training_sessions' "$followup" || fail "followup scenario missing training_sessions affected table check"
rg -q 'training_plans' "$followup" || fail "followup scenario missing training_plans affected table check"
rg -q 'chat_messages' "$followup" || fail "followup scenario missing chat_messages affected table check"
rg -q '/rest/v1/snapshot_refresh_events\?select=id,request_id,status' "$followup" || fail "followup scenario missing snapshot event check"
rg -q 'cards_json' "$followup" || fail "followup scenario missing cards payload check"

echo "phase2 scenario writeback consistency contract present"
