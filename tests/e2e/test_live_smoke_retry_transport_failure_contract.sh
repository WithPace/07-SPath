#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"

fail() {
  echo "$1" >&2
  exit 1
}

test -f "$helper" || fail "missing helper"

# shellcheck source=tests/e2e/_shared/orchestrator_retry.sh
source "$helper" || fail "failed to source helper"

uid_counter_file=$(mktemp)
curl_counter_file=$(mktemp)
echo "0" >"$uid_counter_file"
echo "0" >"$curl_counter_file"

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

reset_curl_counter() {
  echo "0" >"$curl_counter_file"
}

orchestrator_build_payload() {
  echo '{}'
}

sleep_calls=()
sleep() {
  sleep_calls+=("$1")
  :
}

curl_fail_until=0
curl_always_fail=0
curl() {
  local current
  current=$(cat "$curl_counter_file")
  current=$((current + 1))
  echo "$current" >"$curl_counter_file"

  if [ "$curl_always_fail" = "1" ] || [ "$current" -le "$curl_fail_until" ]; then
    echo "curl transport error" >&2
    return 28
  fi
  echo "event: done"
}

assert_sleep_sequence() {
  local label="$1"
  shift
  local actual_count="${#sleep_calls[@]}"
  local expected_count="$#"
  local i=0
  local expected

  [ "$actual_count" -eq "$expected_count" ] || fail "${label}: sleep call count mismatch"
  for expected in "$@"; do
    [ "${sleep_calls[$i]}" = "$expected" ] || fail "${label}: sleep_calls[$i] mismatch"
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
  rm -f "$uid_counter_file" "$curl_counter_file"
}
trap cleanup EXIT

# Scenario A: first transport failure then success should retry and succeed.
reset_uid_counter
reset_curl_counter
request_ids=()
sleep_calls=()
curl_fail_until=1
curl_always_fail=0

if ! ORCH_MAX_ATTEMPTS=4 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "transport_retry_then_success" "0" >/dev/null 2>/dev/null; then
  fail "scenario_a: should succeed after transport retry"
fi

[ "${ORCH_LAST_RESULT:-}" = "success" ] || fail "scenario_a: result mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "2/4" ] || fail "scenario_a: attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "1" ] || fail "scenario_a: retry count mismatch"
[ "${#request_ids[@]}" -eq 2 ] || fail "scenario_a: request_ids count mismatch"
assert_sleep_sequence "scenario_a" "1"

# Scenario B: transport failure exhausted should fail gracefully with deterministic state.
reset_uid_counter
reset_curl_counter
request_ids=()
sleep_calls=()
curl_fail_until=0
curl_always_fail=1

if ORCH_MAX_ATTEMPTS=3 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "transport_exhausted" "0" >/dev/null 2>/dev/null; then
  fail "scenario_b: should fail when transport errors are exhausted"
fi

[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "scenario_b: result mismatch"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "transport_error_exhausted" ] || fail "scenario_b: reason mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "3/3" ] || fail "scenario_b: attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "2" ] || fail "scenario_b: retry count mismatch"
[ "${#request_ids[@]}" -eq 3 ] || fail "scenario_b: request_ids count mismatch"
assert_sleep_sequence "scenario_b" "1" "2"

echo "live smoke retry transport failure contract present"
