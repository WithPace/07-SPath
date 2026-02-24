#!/usr/bin/env bash

orchestrator_build_payload() {
  local child_id="$1"
  local prompt="$2"
  local module="$3"
  local request_id="$4"

  if [ -n "$module" ]; then
    jq -cn \
      --arg child_id "$child_id" \
      --arg message "$prompt" \
      --arg module "$module" \
      --arg request_id "$request_id" \
      '{child_id:$child_id,message:$message,module:$module,request_id:$request_id}'
    return
  fi

  jq -cn \
    --arg child_id "$child_id" \
    --arg message "$prompt" \
    --arg request_id "$request_id" \
    '{child_id:$child_id,message:$message,request_id:$request_id}'
}

orchestrator_call_with_retry() {
  local module="$1"
  local prompt="$2"
  local require_cards="${3:-0}"
  local max_attempts="${ORCH_MAX_ATTEMPTS:-4}"
  local base_delay_seconds="${ORCH_RETRY_BASE_DELAY_SECONDS:-1}"
  local attempt request_id response payload sleep_seconds module_label

  module_label="${module:-chat_casual}"
  ORCH_LAST_REQUEST_ID=""
  ORCH_LAST_RESPONSE=""

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    request_id=$(uid)
    request_ids+=("$request_id")

    payload=$(orchestrator_build_payload "$child_id" "$prompt" "$module" "$request_id")
    response=$(curl "${curl_common[@]}" -N --max-time 180 -X POST "${SUPABASE_URL}/functions/v1/orchestrator" \
      -H "apikey: ${SUPABASE_ANON_KEY}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Content-Type: application/json" \
      -d "$payload")

    if echo "$response" | grep -q "event: done"; then
      if [ "$require_cards" = "1" ] && ! echo "$response" | grep -q "\"cards\""; then
        ORCH_LAST_REQUEST_ID="$request_id"
        ORCH_LAST_RESPONSE="$response"
        echo "orchestrator ${module_label} response missing cards payload" >&2
        return 1
      fi

      ORCH_LAST_REQUEST_ID="$request_id"
      ORCH_LAST_RESPONSE="$response"
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && echo "$response" | grep -q "WORKER_LIMIT"; then
      sleep_seconds=$((base_delay_seconds * (1 << (attempt - 1))))
      echo "orchestrator ${module_label} retry on WORKER_LIMIT: attempt ${attempt}/${max_attempts}, sleep=${sleep_seconds}s" >&2
      sleep "$sleep_seconds"
      continue
    fi

    ORCH_LAST_REQUEST_ID="$request_id"
    ORCH_LAST_RESPONSE="$response"
    return 1
  done

  return 1
}
