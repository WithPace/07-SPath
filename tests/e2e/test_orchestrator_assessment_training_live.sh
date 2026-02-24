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
email="codex.assess.train.${run_id}@example.com"
password="CodexAssessTrain#${run_id}"
user_id=""
child_id=""
request_ids=()
assessment_request_id=""
training_request_id=""
last_request_id=""

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

  if [ -n "${child_id:-}" ]; then
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/chat_messages?child_id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/conversations?child_id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/care_teams?child_id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/training_plans?child_id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${curl_common[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/assessments?child_id=eq.${child_id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
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

user_payload=$(jq -cn --arg id "$user_id" --arg now "$(ts)" '[{id:$id, phone:null, name:"Assess Train User", avatar_url:null, roles:["parent"], vip_level:"free", created_at:$now, updated_at:$now}]')

curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "$user_payload" >/dev/null

child_resp=$(curl "${curl_common[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
  "${service_headers[@]}" \
  -H "Prefer: return=representation" \
  -d "[{\"nickname\":\"评估训练宝宝\",\"real_name\":\"Assess Train Child\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

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

call_orchestrator_module() {
  local module="$1"
  local prompt="$2"
  local attempt resp rid
  local max_attempts=3

  for attempt in 1 2 3; do
    rid=$(uid)
    request_ids+=("$rid")
    resp=$(curl "${curl_common[@]}" -N --max-time 180 -X POST "${SUPABASE_URL}/functions/v1/orchestrator" \
      -H "apikey: ${SUPABASE_ANON_KEY}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Content-Type: application/json" \
      -d "{\"child_id\":\"${child_id}\",\"message\":\"${prompt}\",\"module\":\"${module}\",\"request_id\":\"${rid}\"}")

    if echo "$resp" | grep -q "event: done"; then
      last_request_id="$rid"
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && echo "$resp" | grep -q "WORKER_LIMIT"; then
      sleep "$attempt"
      continue
    fi

    echo "orchestrator ${module} response missing done event" >&2
    echo "$resp" >&2
    return 1
  done

  return 1
}

call_orchestrator_module "assessment" "请帮我做一次简短发育评估并给出风险等级"
assessment_request_id="$last_request_id"

call_orchestrator_module "training_advice" "基于刚才评估给我一个一周训练建议"
training_request_id="$last_request_id"

assess_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/assessments?select=id,type,risk_level,assessed_by&child_id=eq.${child_id}&assessed_by=eq.${user_id}&order=created_at.desc&limit=5" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

assess_count=$(echo "$assess_resp" | jq 'length')
if [ "$assess_count" -lt 1 ]; then
  echo "assessments side effects missing" >&2
  echo "$assess_resp" >&2
  exit 1
fi

plan_resp=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/training_plans?select=id,title,status,created_by&child_id=eq.${child_id}&created_by=eq.${user_id}&order=created_at.desc&limit=5" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

plan_count=$(echo "$plan_resp" | jq 'length')
if [ "$plan_count" -lt 1 ]; then
  echo "training_plans side effects missing" >&2
  echo "$plan_resp" >&2
  exit 1
fi

op_assess=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${assessment_request_id}&action_name=eq.assessment_generate" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
op_assess_count=$(echo "$op_assess" | jq 'length')
if [ "$op_assess_count" -lt 1 ]; then
  echo "assessment operation_logs missing" >&2
  echo "$op_assess" >&2
  exit 1
fi

op_training=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/operation_logs?select=id,request_id,action_name,final_status&request_id=eq.${training_request_id}&action_name=eq.training_advice_generate" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
op_training_count=$(echo "$op_training" | jq 'length')
if [ "$op_training_count" -lt 1 ]; then
  echo "training operation_logs missing" >&2
  echo "$op_training" >&2
  exit 1
fi

event_assess=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${assessment_request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
event_assess_count=$(echo "$event_assess" | jq 'length')
if [ "$event_assess_count" -lt 1 ]; then
  echo "assessment snapshot_refresh_events missing" >&2
  echo "$event_assess" >&2
  exit 1
fi

event_training=$(curl "${curl_common[@]}" "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?select=id,request_id,status&request_id=eq.${training_request_id}" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")
event_training_count=$(echo "$event_training" | jq 'length')
if [ "$event_training_count" -lt 1 ]; then
  echo "training snapshot_refresh_events missing" >&2
  echo "$event_training" >&2
  exit 1
fi

echo "assessment training live smoke pass"
echo "assessment_request_id=${assessment_request_id}"
echo "training_request_id=${training_request_id}"
echo "user_id=${user_id}"
echo "child_id=${child_id}"
