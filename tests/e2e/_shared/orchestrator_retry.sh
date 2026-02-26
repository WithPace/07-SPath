#!/usr/bin/env bash

ORCH_RETRY_REASON_WORKER_LIMIT="WORKER_LIMIT"
ORCH_RETRY_REASON_TRANSPORT_ERROR="transport_error"
ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED="worker_limit_exhausted"
ORCH_TERMINAL_REASON_DONE_EVENT_MISSING="done_event_missing"
ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING="cards_payload_missing"
ORCH_TERMINAL_REASON_TRANSPORT_ERROR_EXHAUSTED="transport_error_exhausted"

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

orchestrator_sanitize_positive_int() {
  local value="$1"
  local default_value="$2"
  local min_value="$3"
  local max_value="$4"

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$default_value"
    return
  fi

  if [ "$value" -lt "$min_value" ] || [ "$value" -gt "$max_value" ]; then
    echo "$default_value"
    return
  fi

  echo "$value"
}

orchestrator_call_with_retry() {
  local module="$1"
  local prompt="$2"
  local require_cards="${3:-0}"
  local max_attempts
  local base_delay_seconds
  local attempt request_id response payload sleep_seconds module_label failure_reason curl_exit

  max_attempts=$(orchestrator_sanitize_positive_int "${ORCH_MAX_ATTEMPTS:-4}" "4" "2" "6")
  base_delay_seconds=$(orchestrator_sanitize_positive_int "${ORCH_RETRY_BASE_DELAY_SECONDS:-1}" "1" "1" "5")

  module_label="${module:-chat_casual}"
  ORCH_LAST_REQUEST_ID=""
  ORCH_LAST_RESPONSE=""
  ORCH_LAST_RESULT=""
  ORCH_LAST_FAILURE_REASON=""
  ORCH_LAST_ATTEMPT=""
  ORCH_LAST_RETRY_COUNT="0"

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    request_id=$(uid)
    request_ids+=("$request_id")

    payload=$(orchestrator_build_payload "$child_id" "$prompt" "$module" "$request_id")
    curl_exit=0
    response=$(curl "${curl_common[@]}" -N --max-time 180 -X POST "${SUPABASE_URL}/functions/v1/orchestrator" \
      -H "apikey: ${SUPABASE_ANON_KEY}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Content-Type: application/json" \
      -d "$payload") || curl_exit=$?

    if [ "$curl_exit" -ne 0 ]; then
      if [ "$attempt" -lt "$max_attempts" ]; then
        ORCH_LAST_RETRY_COUNT=$((ORCH_LAST_RETRY_COUNT + 1))
        sleep_seconds=$((base_delay_seconds * (1 << (attempt - 1))))
        echo "orchestrator retry: module=${module_label} request_id=${request_id} attempt=${attempt}/${max_attempts} sleep_seconds=${sleep_seconds} reason=${ORCH_RETRY_REASON_TRANSPORT_ERROR} exit_code=${curl_exit}" >&2
        sleep "$sleep_seconds"
        continue
      fi

      failure_reason="${ORCH_TERMINAL_REASON_TRANSPORT_ERROR_EXHAUSTED}"
      echo "orchestrator terminal_failure: module=${module_label} request_id=${request_id} attempt=${attempt}/${max_attempts} reason=${failure_reason} exit_code=${curl_exit}" >&2
      ORCH_LAST_REQUEST_ID="$request_id"
      ORCH_LAST_RESPONSE="transport_error_exit_code=${curl_exit}${response:+ ${response}}"
      ORCH_LAST_RESULT="failure"
      ORCH_LAST_FAILURE_REASON="${failure_reason}"
      ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"
      return 1
    fi

    if echo "$response" | grep -q "event: done"; then
      if [ "$require_cards" = "1" ] && ! echo "$response" | grep -q "\"cards\""; then
        failure_reason="${ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING}"
        echo "orchestrator terminal_failure: module=${module_label} request_id=${request_id} attempt=${attempt}/${max_attempts} reason=${failure_reason}" >&2
        ORCH_LAST_REQUEST_ID="$request_id"
        ORCH_LAST_RESPONSE="$response"
        ORCH_LAST_RESULT="failure"
        ORCH_LAST_FAILURE_REASON="${failure_reason}"
        ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"
        return 1
      fi

      ORCH_LAST_REQUEST_ID="$request_id"
      ORCH_LAST_RESPONSE="$response"
      ORCH_LAST_RESULT="success"
      ORCH_LAST_FAILURE_REASON=""
      ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && echo "$response" | grep -q "${ORCH_RETRY_REASON_WORKER_LIMIT}"; then
      ORCH_LAST_RETRY_COUNT=$((ORCH_LAST_RETRY_COUNT + 1))
      sleep_seconds=$((base_delay_seconds * (1 << (attempt - 1))))
      echo "orchestrator retry: module=${module_label} request_id=${request_id} attempt=${attempt}/${max_attempts} sleep_seconds=${sleep_seconds} reason=${ORCH_RETRY_REASON_WORKER_LIMIT}" >&2
      sleep "$sleep_seconds"
      continue
    fi

    failure_reason="${ORCH_TERMINAL_REASON_DONE_EVENT_MISSING}"
    if echo "$response" | grep -q "WORKER_LIMIT"; then
      failure_reason="${ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED}"
    fi
    echo "orchestrator terminal_failure: module=${module_label} request_id=${request_id} attempt=${attempt}/${max_attempts} reason=${failure_reason}" >&2
    ORCH_LAST_REQUEST_ID="$request_id"
    ORCH_LAST_RESPONSE="$response"
    ORCH_LAST_RESULT="failure"
    ORCH_LAST_FAILURE_REASON="${failure_reason}"
    ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"
    return 1
  done

  return 1
}
