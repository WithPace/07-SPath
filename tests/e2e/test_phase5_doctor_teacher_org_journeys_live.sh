#!/usr/bin/env bash
set -euo pipefail

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
email="codex.phase5.roles.${run_id}@example.com"
password="CodexPhase5#${run_id}"
user_id=""
child_id=""
access_token=""
request_ids=()

cleanup() {
  set +e
  local rid
  for rid in "${request_ids[@]:-}"; do
    [ -n "$rid" ] || continue
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

user_payload=$(jq -cn \
  --arg id "$user_id" \
  --arg now "$(ts)" \
  '[{id:$id, phone:null, name:"Phase5 Role User", avatar_url:null, roles:["parent","doctor","teacher","org_admin"], vip_level:"free", created_at:$now, updated_at:$now}]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "$user_payload" >/dev/null

child_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation" \
  -d "[{\"nickname\":\"Phase5宝宝\",\"real_name\":\"Phase5 Child\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

child_id=$(echo "$child_resp" | jq -r '.[0].id // empty')
if [ -z "$child_id" ]; then
  echo "failed to create child" >&2
  echo "$child_resp" >&2
  exit 1
fi

care_team_payload=$(jq -cn \
  --arg uid "$user_id" \
  --arg cid "$child_id" \
  '[
    {user_id:$uid, child_id:$cid, role:"parent", permissions:{}, status:"active"},
    {user_id:$uid, child_id:$cid, role:"doctor", permissions:{}, status:"active"},
    {user_id:$uid, child_id:$cid, role:"teacher", permissions:{}, status:"active"},
    {user_id:$uid, child_id:$cid, role:"org_admin", permissions:{}, status:"active"}
  ]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/care_teams" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "$care_team_payload" >/dev/null

today=$(date -u +%Y-%m-%d)
yesterday=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d"))
PY
)

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/assessments" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"type\":\"screening\",\"result\":{\"score\":9},\"risk_level\":\"low\",\"recommendations\":{\"summary\":\"keep consistent\"},\"assessed_by\":\"${user_id}\"}]" >/dev/null

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/training_plans" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"title\":\"Phase5计划\",\"goals\":{\"focus\":\"专注\"},\"strategies\":{\"items\":[\"模仿练习\"]},\"schedule\":{\"cadence\":\"daily\"},\"difficulty_level\":\"medium\",\"status\":\"active\",\"created_by\":\"${user_id}\"}]" >/dev/null

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/training_sessions" \
  "${service_headers[@]}" \
  -H "Prefer: return=minimal" \
  -d "[{\"child_id\":\"${child_id}\",\"target_skill\":\"共同注意\",\"execution_summary\":\"稳定训练\",\"duration_minutes\":18,\"success_rate\":0.76,\"input_type\":\"text\",\"ai_structured\":{\"k\":\"v\"},\"feedback\":{},\"recorded_by\":\"${user_id}\",\"session_date\":\"${today}\"},{\"child_id\":\"${child_id}\",\"target_skill\":\"语言表达\",\"execution_summary\":\"持续进步\",\"duration_minutes\":22,\"success_rate\":0.82,\"input_type\":\"text\",\"ai_structured\":{\"k\":\"v2\"},\"feedback\":{},\"recorded_by\":\"${user_id}\",\"session_date\":\"${yesterday}\"}]" >/dev/null

call_role_dashboard() {
  local role="$1"
  local prompt="$2"
  local request_id response op_resp op_count
  local max_attempts="${ORCH_MAX_ATTEMPTS:-4}"
  local base_delay_seconds="${ORCH_RETRY_BASE_DELAY_SECONDS:-1}"
  local attempt sleep_seconds

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    request_id=$(uid)
    request_ids+=("$request_id")

    response=$(curl "${curl_common[@]}" -N --max-time 180 -X POST "${SUPABASE_URL}/functions/v1/orchestrator" \
      -H "apikey: ${SUPABASE_ANON_KEY}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Content-Type: application/json" \
      -d "{\"child_id\":\"${child_id}\",\"message\":\"${prompt}\",\"module\":\"dashboard\",\"role\":\"${role}\",\"request_id\":\"${request_id}\"}")

    if ! echo "$response" | grep -q 'event: done'; then
      if [ "$attempt" -lt "$max_attempts" ] && echo "$response" | grep -q 'WORKER_LIMIT'; then
        sleep_seconds=$((base_delay_seconds * (1 << (attempt - 1))))
        echo "phase5 retry: role=${role} request_id=${request_id} attempt=${attempt}/${max_attempts} reason=WORKER_LIMIT sleep_seconds=${sleep_seconds}" >&2
        sleep "$sleep_seconds"
        continue
      fi

      echo "role ${role} dashboard missing done event" >&2
      echo "$response" >&2
      exit 1
    fi

    if ! echo "$response" | grep -q "\"role\":\"${role}\""; then
      echo "role ${role} dashboard done payload missing role echo" >&2
      echo "$response" >&2
      exit 1
    fi

    if ! echo "$response" | grep -q '"cards"'; then
      echo "role ${role} dashboard response missing cards" >&2
      echo "$response" >&2
      exit 1
    fi

    op_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${request_id}&action_name=eq.dashboard_generate" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
    op_count=$(echo "$op_resp" | jq 'length')
    if [ "$op_count" -lt 1 ]; then
      echo "role ${role} dashboard operation_logs missing" >&2
      echo "$op_resp" >&2
      exit 1
    fi

    return 0
  done
}

call_role_dashboard "doctor" "请给我医生视角训练跟进要点"
call_role_dashboard "teacher" "请给我老师视角课堂执行建议"
call_role_dashboard "org_admin" "请给我机构管理视角本周训练概览"

msg_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/chat_messages?select=id&child_id=eq.${child_id}&user_id=eq.${user_id}&edge_function=eq.dashboard" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
msg_count=$(echo "$msg_resp" | jq 'length')
if [ "$msg_count" -lt 3 ]; then
  echo "phase5 multi-role dashboard chat_messages missing" >&2
  echo "$msg_resp" >&2
  exit 1
fi

echo "phase5 doctor/teacher/org_admin live journeys pass"
