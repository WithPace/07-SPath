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

child_id="child-test"
access_token="token-test"
SUPABASE_URL="https://example.invalid"
SUPABASE_ANON_KEY="anon-test"
curl_common=(--silent)
request_ids=()

curl() {
  echo "WORKER_LIMIT"
}

cleanup() {
  rm -f "$uid_counter_file"
}
trap cleanup EXIT

assert_default_runtime_fallback() {
  local label="$1"
  local actual_count="${#request_ids[@]}"

  [ "$actual_count" -eq 4 ] || fail "${label}: request_ids count should fallback to 4 attempts"
  [ "${request_ids[0]}" = "req-1" ] || fail "${label}: request_ids[0] mismatch"
  [ "${request_ids[1]}" = "req-2" ] || fail "${label}: request_ids[1] mismatch"
  [ "${request_ids[2]}" = "req-3" ] || fail "${label}: request_ids[2] mismatch"
  [ "${request_ids[3]}" = "req-4" ] || fail "${label}: request_ids[3] mismatch"

  [ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "${label}: ORCH_LAST_RESULT mismatch"
  [ "${ORCH_LAST_FAILURE_REASON:-}" = "worker_limit_exhausted" ] || fail "${label}: ORCH_LAST_FAILURE_REASON mismatch"
  [ "${ORCH_LAST_ATTEMPT:-}" = "4/4" ] || fail "${label}: ORCH_LAST_ATTEMPT should fallback to 4/4"
  [ "${ORCH_LAST_RETRY_COUNT:-}" = "3" ] || fail "${label}: ORCH_LAST_RETRY_COUNT should fallback to 3"

  [ "${#sleep_calls[@]}" -eq 3 ] || fail "${label}: sleep call count should be 3"
  [ "${sleep_calls[0]}" = "1" ] || fail "${label}: sleep_calls[0] should fallback to 1"
  [ "${sleep_calls[1]}" = "2" ] || fail "${label}: sleep_calls[1] should fallback to 2"
  [ "${sleep_calls[2]}" = "4" ] || fail "${label}: sleep_calls[2] should fallback to 4"
}

run_case() {
  local label="$1"
  local attempts="$2"
  local base_delay="$3"
  local rc

  reset_uid_counter
  request_ids=()
  sleep_calls=()

  ORCH_MAX_ATTEMPTS="$attempts" \
  ORCH_RETRY_BASE_DELAY_SECONDS="$base_delay" \
  orchestrator_call_with_retry "training" "$label" "0" >/dev/null 2>/dev/null
  rc=$?
  [ "$rc" -ne 0 ] || fail "${label}: call should fail under WORKER_LIMIT loop"

  assert_default_runtime_fallback "$label"
}

# Scenario A: invalid low values should fallback to defaults (4 / 1).
run_case "low_out_of_range" "1" "0"

# Scenario B: invalid high values should fallback to defaults (4 / 1).
run_case "high_out_of_range" "99" "9"

# Scenario C: invalid non-numeric values should fallback to defaults (4 / 1).
run_case "non_numeric" "abc" "nan"

echo "live smoke retry runtime sanitization contract present"
