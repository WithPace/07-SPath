#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/e2e/_shared/orchestrator_retry.sh
source "${script_dir}/_shared/orchestrator_retry.sh"

if [ ! -f .env ]; then
  echo "missing .env (worktree must have a local copy)" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY SUPABASE_ANON_KEY; do
  if [ -z "${!key:-}" ]; then
    echo "missing env: $key" >&2
    exit 1
  fi
done

uid() {
  python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
}

ts() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

service_headers=(
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}"
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
  -H "Content-Type: application/json"
)

anon_headers=(
  -H "apikey: ${SUPABASE_ANON_KEY}"
  -H "Content-Type: application/json"
)

curl_common=(
  -sS
  --http1.1
  --retry 3
  --retry-delay 1
  --retry-all-errors
)

run_id=$(date +%s)
email="codex.dashboard.${run_id}@example.com"
password="CodexDashboard#${run_id}"
user_id=""
child_id=""
request_ids=()
dashboard_request_id=""

cleanup() {
  set +e

  for rid in "${request_ids[@]:-}"; do
    if [ -z "$rid" ]; then
      continue
    fi
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/operation_logs?request_id=eq.${rid}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?request_id=eq.${rid}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  done

  if [ -n "${child_id:-}" ] && [ -n "${user_id:-}" ]; then
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/chat_messages?child_id=eq.${child_id}&user_id=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/conversations?child_id=eq.${child_id}&user_id=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/care_teams?child_id=eq.${child_id}&user_id=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/training_sessions?child_id=eq.${child_id}&recorded_by=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/training_plans?child_id=eq.${child_id}&created_by=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/assessments?child_id=eq.${child_id}&assessed_by=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  fi

  if [ -n "${child_id:-}" ]; then
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/children?id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  fi

  if [ -n "${user_id:-}" ]; then
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/users?id=eq.${user_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/auth/v1/admin/users/${user_id}" \
      "${service_headers[@]}" >/dev/null
  fi
}

trap cleanup EXIT

create_user_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/auth/v1/admin/users" \
  "${service_headers[@]}" \
  -d "{\"email\":\"${email}\",\"password\":\"${password}\",\"email_confirm\":true}")

user_id=$(echo "$create_user_resp" | jq -r '.id // empty')
if [ -z "$user_id" ]; then
  echo "failed to create auth user" >&2
  echo "$create_user_resp" >&2
  exit 1
fi

login_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  "${anon_headers[@]}" \
  -d "{\"email\":\"${email}\",\"password\":\"${password}\"}")

access_token=$(echo "$login_resp" | jq -r '.access_token // empty')
if [ -z "$access_token" ]; then
  echo "failed to login test user" >&2
  echo "$login_resp" >&2
  exit 1
fi

user_payload=$(jq -cn --arg id "$user_id" --arg now "$(ts)" '[{id:$id, phone:null, name:"Dashboard User", avatar_url:null, roles:["parent"], vip_level:"free", created_at:$now, updated_at:$now}]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "$user_payload" >/dev/null

child_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation" \
  -d "[{\"nickname\":\"看板宝宝\",\"real_name\":\"Dashboard Child\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

child_id=$(echo "$child_resp" | jq -r '.[0].id // empty')
if [ -z "$child_id" ]; then
  echo "failed to create child" >&2
  echo "$child_resp" >&2
  exit 1
fi

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/care_teams" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"user_id\":\"${user_id}\",\"child_id\":\"${child_id}\",\"role\":\"parent\",\"permissions\":{},\"status\":\"active\"}]" >/dev/null

today=$(date -u +%Y-%m-%d)
yesterday=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d"))
PY
)

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/assessments" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"type\":\"screening\",\"result\":{\"score\":12},\"risk_level\":\"medium\",\"recommendations\":{\"summary\":\"keep training\"},\"assessed_by\":\"${user_id}\"}]" >/dev/null

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/training_plans" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"title\":\"本周训练计划\",\"goals\":{\"focus\":\"沟通\"},\"strategies\":{\"items\":[\"眼神对视\"]},\"schedule\":{\"cadence\":\"daily\"},\"difficulty_level\":\"medium\",\"status\":\"active\",\"created_by\":\"${user_id}\"}]" >/dev/null

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/training_sessions" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"target_skill\":\"共同注意\",\"execution_summary\":\"训练顺利\",\"duration_minutes\":20,\"success_rate\":0.8,\"input_type\":\"text\",\"ai_structured\":{\"k\":\"v\"},\"feedback\":{},\"recorded_by\":\"${user_id}\",\"session_date\":\"${today}\"},{\"child_id\":\"${child_id}\",\"target_skill\":\"模仿发音\",\"execution_summary\":\"有进步\",\"duration_minutes\":15,\"success_rate\":0.7,\"input_type\":\"text\",\"ai_structured\":{\"k\":\"v2\"},\"feedback\":{},\"recorded_by\":\"${user_id}\",\"session_date\":\"${yesterday}\"}]" >/dev/null

if ! orchestrator_call_with_retry "dashboard" "给我看本周训练看板并给出洞察" "1"; then
  echo "orchestrator dashboard response missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
dashboard_request_id="$ORCH_LAST_REQUEST_ID"

msg_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/chat_messages?select=id,role,cards_json,edge_function&child_id=eq.${child_id}&user_id=eq.${user_id}&edge_function=eq.dashboard&order=created_at.desc&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
msg_count=$(echo "$msg_resp" | jq 'length')
if [ "$msg_count" -lt 1 ]; then
  echo "dashboard chat_messages missing" >&2
  echo "$msg_resp" >&2
  exit 1
fi

cards_count=$(echo "$msg_resp" | jq '.[0].cards_json | length')
if [ "$cards_count" -lt 1 ]; then
  echo "dashboard cards_json missing" >&2
  echo "$msg_resp" >&2
  exit 1
fi

op_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${dashboard_request_id}&action_name=eq.dashboard_generate" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
op_count=$(echo "$op_resp" | jq 'length')
if [ "$op_count" -lt 1 ]; then
  echo "dashboard operation_logs missing" >&2
  echo "$op_resp" >&2
  exit 1
fi

op_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status,affected_tables&request_id=eq.${dashboard_request_id}&action_name=eq.dashboard_generate" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
has_chat_messages=$(echo "$op_resp" | jq -r '.[0].affected_tables // [] | index("chat_messages") != null')
if [ "$has_chat_messages" != "true" ]; then
  echo "dashboard operation_logs missing chat_messages affected table" >&2
  echo "$op_resp" >&2
  exit 1
fi

event_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${dashboard_request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
event_count=$(echo "$event_resp" | jq 'length')
if [ "$event_count" -lt 1 ]; then
  echo "dashboard snapshot_refresh_events missing" >&2
  echo "$event_resp" >&2
  exit 1
fi

echo "dashboard live smoke pass"
echo "dashboard_request_id=${dashboard_request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
