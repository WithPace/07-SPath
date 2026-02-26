#!/usr/bin/env bash

phase2_uid() {
  python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
}

phase2_ts() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

phase2_load_env() {
  if [ ! -f .env ]; then
    echo "missing .env (worktree must have a local copy)" >&2
    return 1
  fi

  set -a
  # shellcheck disable=SC1091
  source .env
  set +a

  for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY SUPABASE_ANON_KEY; do
    if [ -z "${!key:-}" ]; then
      echo "missing env: $key" >&2
      return 1
    fi
  done

  PHASE2_SERVICE_HEADERS=(
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}"
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
    -H "Content-Type: application/json"
  )

  PHASE2_ANON_HEADERS=(
    -H "apikey: ${SUPABASE_ANON_KEY}"
    -H "Content-Type: application/json"
  )

  PHASE2_CURL_COMMON=(
    -sS
    --http1.1
    --retry 3
    --retry-delay 1
    --retry-all-errors
  )
}

phase2_create_user_and_child() {
  local email="$1"
  local password="$2"
  local user_name="$3"
  local child_nickname="$4"
  local child_real_name="$5"
  local create_user_resp login_resp user_payload child_resp

  create_user_resp=$(curl "${PHASE2_CURL_COMMON[@]}" -X POST "${SUPABASE_URL}/auth/v1/admin/users" \
    "${PHASE2_SERVICE_HEADERS[@]}" \
    -d "{\"email\":\"${email}\",\"password\":\"${password}\",\"email_confirm\":true}")

  user_id=$(echo "$create_user_resp" | jq -r '.id // empty')
  if [ -z "$user_id" ]; then
    echo "failed to create auth user" >&2
    echo "$create_user_resp" >&2
    return 1
  fi

  login_resp=$(curl "${PHASE2_CURL_COMMON[@]}" -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    "${PHASE2_ANON_HEADERS[@]}" \
    -d "{\"email\":\"${email}\",\"password\":\"${password}\"}")

  access_token=$(echo "$login_resp" | jq -r '.access_token // empty')
  if [ -z "$access_token" ]; then
    echo "failed to login test user" >&2
    echo "$login_resp" >&2
    return 1
  fi

  user_payload=$(jq -cn --arg id "$user_id" --arg now "$(phase2_ts)" --arg name "$user_name" \
    '[{id:$id, phone:null, name:$name, avatar_url:null, roles:["parent"], vip_level:"free", created_at:$now, updated_at:$now}]')

  curl "${PHASE2_CURL_COMMON[@]}" -X POST "${SUPABASE_URL}/rest/v1/users" \
    "${PHASE2_SERVICE_HEADERS[@]}" \
    -H "Prefer: return=representation,resolution=merge-duplicates" \
    -d "$user_payload" >/dev/null

  child_resp=$(curl "${PHASE2_CURL_COMMON[@]}" -X POST "${SUPABASE_URL}/rest/v1/children" \
    "${PHASE2_SERVICE_HEADERS[@]}" \
    -H "Prefer: return=representation" \
    -d "[{\"nickname\":\"${child_nickname}\",\"real_name\":\"${child_real_name}\",\"created_by\":\"${user_id}\",\"creator_relation\":\"妈妈\"}]")

  child_id=$(echo "$child_resp" | jq -r '.[0].id // empty')
  if [ -z "$child_id" ]; then
    echo "failed to create child" >&2
    echo "$child_resp" >&2
    return 1
  fi

  curl "${PHASE2_CURL_COMMON[@]}" -X POST "${SUPABASE_URL}/rest/v1/care_teams" \
    "${PHASE2_SERVICE_HEADERS[@]}" \
    -H "Prefer: return=minimal" \
    -d "[{\"user_id\":\"${user_id}\",\"child_id\":\"${child_id}\",\"role\":\"parent\",\"permissions\":{},\"status\":\"active\"}]" >/dev/null
}

phase2_cleanup_request_artifacts() {
  local rid
  for rid in "${request_ids[@]:-}"; do
    if [ -z "$rid" ]; then
      continue
    fi
    curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/operation_logs?request_id=eq.${rid}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
    curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/snapshot_refresh_events?request_id=eq.${rid}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  done
}

phase2_cleanup_child_related() {
  local cid="${1:-}"
  if [ -z "$cid" ]; then
    return 0
  fi

  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/chat_messages?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/conversations?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/care_teams?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/training_sessions?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/training_plans?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/assessments?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/children_profiles?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/children_memory?child_id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/children?id=eq.${cid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
}

phase2_cleanup_user() {
  local uid="${1:-}"
  if [ -z "$uid" ]; then
    return 0
  fi

  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/rest/v1/users?id=eq.${uid}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" >/dev/null
  curl "${PHASE2_CURL_COMMON[@]}" -X DELETE "${SUPABASE_URL}/auth/v1/admin/users/${uid}" \
    "${PHASE2_SERVICE_HEADERS[@]}" >/dev/null
}
