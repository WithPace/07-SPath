#!/usr/bin/env bash
set -uo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"

fail() {
  echo "$1" >&2
  exit 1
}

test -f "$helper" || fail "missing helper"

# shellcheck source=tests/e2e/_shared/orchestrator_retry.sh
source "$helper" || fail "failed to source helper"

uid_counter_file=$(mktemp)
echo "0" >"$uid_counter_file"

uid() {
  local current
  current=$(cat "$uid_counter_file")
  current=$((current + 1))
  echo "$current" >"$uid_counter_file"
  echo "req-${current}"
}

reset_uid_counter() {
  echo "0" >"$uid_counter_file"
}

orchestrator_build_payload() {
  echo '{}'
}

sleep_calls=()
sleep() {
  sleep_calls+=("$1")
  :
}

curl_counter_file=$(mktemp)
curl_responses_file=$(mktemp)
echo "0" >"$curl_counter_file"

set_curl_responses() {
  : >"$curl_responses_file"
  for line in "$@"; do
    printf '%s\n' "$line" >>"$curl_responses_file"
  done
  echo "0" >"$curl_counter_file"
}

curl() {
  local current line_no response
  current=$(cat "$curl_counter_file")
  line_no=$((current + 1))
  echo "$line_no" >"$curl_counter_file"

  response=$(sed -n "${line_no}p" "$curl_responses_file")
  if [ -z "$response" ]; then
    echo "event: done"
    return
  fi
  echo "$response"
}

assert_sleep_sequence() {
  local label="$1"
  shift
  local actual_count="${#sleep_calls[@]}"
  local expected_count="$#"

  [ "$actual_count" -eq "$expected_count" ] || fail "${label}: sleep call count mismatch"
  local i=0
  local val
  for val in "$@"; do
    [ "${sleep_calls[$i]}" = "$val" ] || fail "${label}: sleep_calls[$i] mismatch"
    i=$((i + 1))
  done
}

child_id="child-test"
access_token="token-test"
SUPABASE_URL="https://example.invalid"
SUPABASE_ANON_KEY="anon-test"
curl_common=(--silent)
request_ids=()

cleanup() {
  rm -f "$uid_counter_file" "$curl_counter_file" "$curl_responses_file"
}
trap cleanup EXIT

# Scenario A: worker-limit x2 then success, base_delay=3 -> sleeps 3,6.
reset_uid_counter
request_ids=()
sleep_calls=()
set_curl_responses "WORKER_LIMIT" "WORKER_LIMIT" "event: done"

ORCH_MAX_ATTEMPTS=5 ORCH_RETRY_BASE_DELAY_SECONDS=3 orchestrator_call_with_retry "training" "retry_then_success" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "scenario_a: should succeed"
assert_sleep_sequence "scenario_a" "3" "6"
[ "${ORCH_LAST_RESULT:-}" = "success" ] || fail "scenario_a: result mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "3/5" ] || fail "scenario_a: attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "2" ] || fail "scenario_a: retry count mismatch"
[ "${#request_ids[@]}" -eq 3 ] || fail "scenario_a: request_ids count mismatch"

# Scenario B: worker-limit exhausted, max_attempts=3 base_delay=3 -> sleeps 3,6 only.
reset_uid_counter
request_ids=()
sleep_calls=()
set_curl_responses "WORKER_LIMIT" "WORKER_LIMIT" "WORKER_LIMIT"

ORCH_MAX_ATTEMPTS=3 ORCH_RETRY_BASE_DELAY_SECONDS=3 orchestrator_call_with_retry "training" "retry_exhausted" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "scenario_b: should fail"
assert_sleep_sequence "scenario_b" "3" "6"
[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "scenario_b: result mismatch"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "worker_limit_exhausted" ] || fail "scenario_b: reason mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "3/3" ] || fail "scenario_b: attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "2" ] || fail "scenario_b: retry count mismatch"
[ "${#request_ids[@]}" -eq 3 ] || fail "scenario_b: request_ids count mismatch"

# Scenario C: non-retriable terminal payload -> no sleep.
reset_uid_counter
request_ids=()
sleep_calls=()
set_curl_responses "unexpected payload"

ORCH_MAX_ATTEMPTS=5 ORCH_RETRY_BASE_DELAY_SECONDS=3 orchestrator_call_with_retry "training" "non_retryable_terminal" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "scenario_c: should fail"
assert_sleep_sequence "scenario_c"
[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "scenario_c: result mismatch"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "done_event_missing" ] || fail "scenario_c: reason mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "1/5" ] || fail "scenario_c: attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "0" ] || fail "scenario_c: retry count mismatch"
[ "${#request_ids[@]}" -eq 1 ] || fail "scenario_c: request_ids count mismatch"

echo "live smoke retry backoff timing contract present"
