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
email="codex.smoke.${run_id}@example.com"
password="CodexSmoke#${run_id}"
request_id=$(uid)

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

user_payload=$(jq -cn --arg id "$user_id" --arg now "$(ts)" '[{id:$id, phone:null, name:"Smoke User", avatar_url:null, roles:["parent"], vip_level:"free", created_at:$now, updated_at:$now}]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "$user_payload" >/dev/null

child_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation" \
  -d "[{\"nickname\":\"测试宝宝\",\"real_name\":\"Smoke Child\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

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

orchestrator_resp=$(curl "${curl_common[@]}" -N --max-time 180 -X POST "${SUPABASE_URL}/functions/v1/orchestrator" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${access_token}" \
  -H "Content-Type: application/json" \
  -d "{\"child_id\":\"${child_id}\",\"message\":\"请给我一个今天在家训练的小建议\",\"request_id\":\"${request_id}\"}")

if echo "$orchestrator_resp" | grep -q "event: error"; then
  echo "orchestrator returned error event" >&2
  echo "$orchestrator_resp" >&2
  exit 1
fi

if ! echo "$orchestrator_resp" | grep -q "event: done"; then
  echo "orchestrator response missing done event" >&2
  echo "$orchestrator_resp" >&2
  exit 1
fi

messages_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/chat_messages?select=role,content,conversation_id,created_at&child_id=eq.${child_id}&user_id=eq.${user_id}&order=created_at.desc&limit=20" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

user_count=$(echo "$messages_resp" | jq '[.[] | select(.role=="user")] | length')
assistant_count=$(echo "$messages_resp" | jq '[.[] | select(.role=="assistant")] | length')

if [ "$user_count" -lt 1 ] || [ "$assistant_count" -lt 1 ]; then
  echo "chat_messages side effects missing" >&2
  echo "$messages_resp" >&2
  exit 1
fi

op_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${request_id}&action_name=eq.chat_casual_reply" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

op_count=$(echo "$op_resp" | jq 'length')
if [ "$op_count" -lt 1 ]; then
  echo "operation_logs side effects missing" >&2
  echo "$op_resp" >&2
  exit 1
fi

event_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

event_count=$(echo "$event_resp" | jq 'length')
if [ "$event_count" -lt 1 ]; then
  echo "snapshot_refresh_events side effects missing" >&2
  echo "$event_resp" >&2
  exit 1
fi

conv_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/conversations?select=id,message_count,last_message_at,user_id,child_id&user_id=eq.${user_id}&child_id=eq.${child_id}&order=created_at.desc&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

message_count=$(echo "$conv_resp" | jq -r '.[0].message_count // 0')
if [ "$message_count" -lt 2 ]; then
  echo "conversation sync side effects missing" >&2
  echo "$conv_resp" >&2
  exit 1
fi

echo "live smoke pass"
echo "request_id=${request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
