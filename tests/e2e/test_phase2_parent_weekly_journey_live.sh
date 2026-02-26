#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/e2e/_shared/orchestrator_retry.sh
source "${script_dir}/_shared/orchestrator_retry.sh"
# shellcheck source=tests/e2e/_shared/live_smoke_lib.sh
source "${script_dir}/_shared/live_smoke_lib.sh"

phase2_load_env

uid() {
  phase2_uid
}

curl_common=("${PHASE2_CURL_COMMON[@]}")
service_headers=("${PHASE2_SERVICE_HEADERS[@]}")
anon_headers=("${PHASE2_ANON_HEADERS[@]}")

run_id=$(date +%s)
email="phase2.weekly.${run_id}@example.com"
password="Phase2Weekly#${run_id}"
user_id=""
child_id=""
access_token=""
request_ids=()
assessment_request_id=""
training_advice_request_id=""
training_request_id=""
training_record_request_id=""
dashboard_request_id=""

cleanup() {
  set +e
  phase2_cleanup_request_artifacts
  phase2_cleanup_child_related "${child_id:-}"
  phase2_cleanup_user "${user_id:-}"
}
trap cleanup EXIT

phase2_create_user_and_child \
  "$email" \
  "$password" \
  "Phase2 Weekly User" \
  "阶段二周旅程宝宝" \
  "Phase2 Weekly Child"

assert_operation_log() {
  local request_id="$1"
  local action_name="$2"
  local resp count

  resp=$(curl "${curl_common[@]}" \
    "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status,affected_tables&request_id=eq.${request_id}&action_name=eq.${action_name}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
  count=$(echo "$resp" | jq 'length')
  if [ "$count" -lt 1 ]; then
    echo "missing operation_log action=${action_name} request_id=${request_id}" >&2
    echo "$resp" >&2
    exit 1
  fi
}

assert_snapshot_event() {
  local request_id="$1"
  local resp count
  resp=$(curl "${curl_common[@]}" \
    "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${request_id}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
  count=$(echo "$resp" | jq 'length')
  if [ "$count" -lt 1 ]; then
    echo "missing snapshot_refresh_event request_id=${request_id}" >&2
    echo "$resp" >&2
    exit 1
  fi
}

if ! orchestrator_call_with_retry "assessment" "请做一次简短评估并指出本周重点训练方向"; then
  echo "assessment step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
assessment_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "training_advice" "基于评估结论给出七天家庭训练建议"; then
  echo "training_advice step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
training_advice_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "training" "给我按天分解的一周训练计划"; then
  echo "training step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
training_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "training_record" "今天完成了15分钟共同注意训练，完成率80%"; then
  echo "training_record step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
training_record_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "dashboard" "请生成本周看板并给出下一步建议" "1"; then
  echo "dashboard step missing done/cards event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
dashboard_request_id="$ORCH_LAST_REQUEST_ID"

assert_operation_log "$assessment_request_id" "assessment_generate"
assert_operation_log "$training_advice_request_id" "training_advice_generate"
assert_operation_log "$training_request_id" "training_generate"
assert_operation_log "$training_record_request_id" "training_record_create"
assert_operation_log "$dashboard_request_id" "dashboard_generate"

assert_snapshot_event "$assessment_request_id"
assert_snapshot_event "$training_advice_request_id"
assert_snapshot_event "$training_request_id"
assert_snapshot_event "$training_record_request_id"
assert_snapshot_event "$dashboard_request_id"

assess_count=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/assessments?select=id&child_id=eq.${child_id}&assessed_by=eq.${user_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq 'length')
if [ "$assess_count" -lt 1 ]; then
  echo "weekly journey missing assessments writeback" >&2
  exit 1
fi

plan_count=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/training_plans?select=id&child_id=eq.${child_id}&created_by=eq.${user_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq 'length')
if [ "$plan_count" -lt 1 ]; then
  echo "weekly journey missing training_plans writeback" >&2
  exit 1
fi

session_count=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/training_sessions?select=id&child_id=eq.${child_id}&recorded_by=eq.${user_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq 'length')
if [ "$session_count" -lt 1 ]; then
  echo "weekly journey missing training_sessions writeback" >&2
  exit 1
fi

memory_focus=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/children_memory?select=current_focus&child_id=eq.${child_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq -r '.[0].current_focus // empty')
if [ -z "$memory_focus" ]; then
  echo "weekly journey missing children_memory current_focus" >&2
  exit 1
fi

dashboard_msg_resp=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/chat_messages?select=id,cards_json,edge_function&child_id=eq.${child_id}&user_id=eq.${user_id}&edge_function=eq.dashboard&order=created_at.desc&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
dashboard_msg_count=$(echo "$dashboard_msg_resp" | jq 'length')
if [ "$dashboard_msg_count" -lt 1 ]; then
  echo "weekly journey missing dashboard chat message" >&2
  echo "$dashboard_msg_resp" >&2
  exit 1
fi

dashboard_cards_count=$(echo "$dashboard_msg_resp" | jq '.[0].cards_json | length')
if [ "$dashboard_cards_count" -lt 1 ]; then
  echo "weekly journey missing dashboard cards payload" >&2
  echo "$dashboard_msg_resp" >&2
  exit 1
fi

conv_resp=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/conversations?select=id,message_count&child_id=eq.${child_id}&user_id=eq.${user_id}&order=updated_at.desc&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
conv_count=$(echo "$conv_resp" | jq 'length')
if [ "$conv_count" -lt 1 ]; then
  echo "weekly journey missing conversation" >&2
  echo "$conv_resp" >&2
  exit 1
fi
msg_count=$(echo "$conv_resp" | jq '.[0].message_count // 0')
if [ "$msg_count" -lt 2 ]; then
  echo "weekly journey conversation message_count too small: ${msg_count}" >&2
  echo "$conv_resp" >&2
  exit 1
fi

echo "phase2 weekly journey live pass"
echo "assessment_request_id=${assessment_request_id}"
echo "training_advice_request_id=${training_advice_request_id}"
echo "training_request_id=${training_request_id}"
echo "training_record_request_id=${training_record_request_id}"
echo "dashboard_request_id=${dashboard_request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
