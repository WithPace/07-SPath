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
email="phase2.dashboard.followup.${run_id}@example.com"
password="Phase2DashFollow#${run_id}"
user_id=""
child_id=""
access_token=""
request_ids=()
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
  "Phase2 Dashboard Followup User" \
  "阶段二看板跟进宝宝" \
  "Phase2 Dashboard Followup Child"

assert_action_exists() {
  local request_id="$1"
  local action_name="$2"
  local resp count
  resp=$(curl "${curl_common[@]}" \
    "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status,affected_tables&request_id=eq.${request_id}&action_name=eq.${action_name}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
  count=$(echo "$resp" | jq 'length')
  if [ "$count" -lt 1 ]; then
    echo "missing operation log for action=${action_name} request_id=${request_id}" >&2
    echo "$resp" >&2
    exit 1
  fi
}

if ! orchestrator_call_with_retry "training" "请给我本周每天可执行的训练安排"; then
  echo "followup training step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
training_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "training_record" "今天完成了20分钟模仿训练，完成率70%"; then
  echo "followup training_record step missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
training_record_request_id="$ORCH_LAST_REQUEST_ID"

if ! orchestrator_call_with_retry "dashboard" "基于训练执行情况给我看板总结和明日建议" "1"; then
  echo "followup dashboard step missing done/cards event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
dashboard_request_id="$ORCH_LAST_REQUEST_ID"

assert_action_exists "$training_request_id" "training_generate"
assert_action_exists "$training_record_request_id" "training_record_create"
assert_action_exists "$dashboard_request_id" "dashboard_generate"

if [ "$training_request_id" = "$training_record_request_id" ] || [ "$training_request_id" = "$dashboard_request_id" ] || [ "$training_record_request_id" = "$dashboard_request_id" ]; then
  echo "request_id collision detected in followup scenario" >&2
  exit 1
fi

dash_op=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,affected_tables&request_id=eq.${dashboard_request_id}&action_name=eq.dashboard_generate" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

has_training_sessions=$(echo "$dash_op" | jq -r '.[0].affected_tables // [] | index("training_sessions") != null')
has_training_plans=$(echo "$dash_op" | jq -r '.[0].affected_tables // [] | index("training_plans") != null')
has_chat_messages=$(echo "$dash_op" | jq -r '.[0].affected_tables // [] | index("chat_messages") != null')
if [ "$has_training_sessions" != "true" ] || [ "$has_training_plans" != "true" ] || [ "$has_chat_messages" != "true" ]; then
  echo "dashboard followup affected_tables incomplete" >&2
  echo "$dash_op" >&2
  exit 1
fi

event_resp=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${dashboard_request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
event_count=$(echo "$event_resp" | jq 'length')
if [ "$event_count" -lt 1 ]; then
  echo "dashboard followup missing snapshot event" >&2
  echo "$event_resp" >&2
  exit 1
fi

dashboard_msg_resp=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/chat_messages?select=id,cards_json,edge_function&child_id=eq.${child_id}&user_id=eq.${user_id}&edge_function=eq.dashboard&order=created_at.desc&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
dashboard_msg_count=$(echo "$dashboard_msg_resp" | jq 'length')
if [ "$dashboard_msg_count" -lt 1 ]; then
  echo "dashboard followup missing dashboard chat message" >&2
  echo "$dashboard_msg_resp" >&2
  exit 1
fi

dashboard_cards_count=$(echo "$dashboard_msg_resp" | jq '.[0].cards_json | length')
if [ "$dashboard_cards_count" -lt 1 ]; then
  echo "dashboard followup missing cards payload" >&2
  echo "$dashboard_msg_resp" >&2
  exit 1
fi

plan_count=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/training_plans?select=id&child_id=eq.${child_id}&created_by=eq.${user_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq 'length')
if [ "$plan_count" -lt 1 ]; then
  echo "dashboard followup missing training plan side effects" >&2
  exit 1
fi

session_count=$(curl "${curl_common[@]}" \
  "${SUPABASE_URL}/rest/v1/training_sessions?select=id&child_id=eq.${child_id}&recorded_by=eq.${user_id}&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" | jq 'length')
if [ "$session_count" -lt 1 ]; then
  echo "dashboard followup missing training session side effects" >&2
  exit 1
fi

echo "phase2 dashboard followup live pass"
echo "training_request_id=${training_request_id}"
echo "training_record_request_id=${training_record_request_id}"
echo "dashboard_request_id=${dashboard_request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
