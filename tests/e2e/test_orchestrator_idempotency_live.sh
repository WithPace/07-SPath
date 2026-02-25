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

random_uuid() {
  python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
}

uid() {
  if [ -n "${ORCH_FIXED_REQUEST_ID:-}" ]; then
    echo "${ORCH_FIXED_REQUEST_ID}"
    return
  fi
  random_uuid
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
email="codex.idempotency.${run_id}@example.com"
password="CodexIdempotency#${run_id}"
user_id=""
child_id=""
request_ids=()
idempotent_request_id=""

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

user_payload=$(jq -cn --arg id "$user_id" --arg now "$(ts)" '[{id:$id, phone:null, name:"Idempotency User", avatar_url:null, roles:["parent"], vip_level:"free", created_at:$now, updated_at:$now}]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "$user_payload" >/dev/null

child_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation" \
  -d "[{\"nickname\":\"幂等宝宝\",\"real_name\":\"Idempotency Child\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

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

ORCH_FIXED_REQUEST_ID=$(random_uuid)
idempotent_request_id="$ORCH_FIXED_REQUEST_ID"
request_ids+=("$idempotent_request_id")

if ! orchestrator_call_with_retry "" "请给我一个可执行的家庭训练建议"; then
  echo "first idempotency call missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
first_response="$ORCH_LAST_RESPONSE"

messages_before=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/chat_messages?select=id,role,child_id,user_id&child_id=eq.${child_id}&user_id=eq.${user_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
user_count_before=$(echo "$messages_before" | jq '[.[] | select(.role=="user")] | length')
assistant_count_before=$(echo "$messages_before" | jq '[.[] | select(.role=="assistant")] | length')
if [ "$user_count_before" -lt 1 ] || [ "$assistant_count_before" -lt 1 ]; then
  echo "first call side effects missing chat messages" >&2
  echo "$messages_before" >&2
  exit 1
fi

if ! orchestrator_call_with_retry "" "请给我一个可执行的家庭训练建议"; then
  echo "second idempotency call missing done event" >&2
  echo "$ORCH_LAST_RESPONSE" >&2
  exit 1
fi
second_response="$ORCH_LAST_RESPONSE"

if ! echo "$second_response" | grep -q '"idempotent":true'; then
  echo "second response missing idempotent=true" >&2
  echo "first_response=$first_response" >&2
  echo "second_response=$second_response" >&2
  exit 1
fi

op_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${idempotent_request_id}&action_name=eq.chat_casual_reply&final_status=eq.completed" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
op_count=$(echo "$op_resp" | jq 'length')
if [ "$op_count" -ne 1 ]; then
  echo "idempotency failed: expected exactly 1 completed operation_log" >&2
  echo "$op_resp" >&2
  exit 1
fi

messages_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/chat_messages?select=id,role,child_id,user_id&child_id=eq.${child_id}&user_id=eq.${user_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

user_count=$(echo "$messages_resp" | jq '[.[] | select(.role=="user")] | length')
assistant_count=$(echo "$messages_resp" | jq '[.[] | select(.role=="assistant")] | length')
if [ "$user_count" -ne "$user_count_before" ] || [ "$assistant_count" -ne "$assistant_count_before" ]; then
  echo "idempotency failed: second call changed chat message counts" >&2
  echo "before: user=${user_count_before}, assistant=${assistant_count_before}" >&2
  echo "after:  user=${user_count}, assistant=${assistant_count}" >&2
  echo "$messages_resp" >&2
  exit 1
fi

event_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${idempotent_request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
event_count=$(echo "$event_resp" | jq 'length')
if [ "$event_count" -ne 1 ]; then
  echo "idempotency failed: expected exactly 1 snapshot_refresh_event" >&2
  echo "$event_resp" >&2
  exit 1
fi

echo "orchestrator idempotency live smoke pass"
echo "request_id=${idempotent_request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
