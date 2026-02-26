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

next_uid() {
  local current
  current=$(cat "$uid_counter_file")
  current=$((current + 1))
  echo "$current" >"$uid_counter_file"
  echo "req-${current}"
}

uid() {
  next_uid
}

reset_uid_counter() {
  echo "0" >"$uid_counter_file"
}

assert_request_id_trace() {
  local expected_count="$1"
  shift
  local expected_last="$1"
  shift
  local actual_count="${#request_ids[@]}"

  [ "$actual_count" -eq "$expected_count" ] || fail "request_ids count mismatch: expected ${expected_count}, got ${actual_count}"

  local index=0
  for expected in "$@"; do
    [ "${request_ids[$index]}" = "$expected" ] || fail "request_ids[$index] mismatch: expected ${expected}, got ${request_ids[$index]}"
    index=$((index + 1))
  done

  [ "${ORCH_LAST_REQUEST_ID:-}" = "$expected_last" ] || fail "ORCH_LAST_REQUEST_ID mismatch: expected ${expected_last}, got ${ORCH_LAST_REQUEST_ID:-}"
}

orchestrator_build_payload() {
  echo '{}'
}

sleep() {
  :
}

child_id="child-test"
access_token="token-test"
SUPABASE_URL="https://example.invalid"
SUPABASE_ANON_KEY="anon-test"
curl_common=(--silent)
request_ids=()

cleanup() {
  rm -f "$uid_counter_file" "${case2_counter_file:-}"
}
trap cleanup EXIT

# Case 1: success on first attempt.
reset_uid_counter
request_ids=()
curl() {
  echo "event: done"
}

ORCH_MAX_ATTEMPTS=2 orchestrator_call_with_retry "training" "ok" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "case1 should succeed"
assert_request_id_trace 1 "req-1" "req-1"
[ "${ORCH_LAST_ATTEMPT:-}" = "1/2" ] || fail "case1 attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "0" ] || fail "case1 retry count mismatch"

# Case 2: worker-limit then success on second attempt.
reset_uid_counter
request_ids=()
case2_counter_file=$(mktemp)
echo "0" >"$case2_counter_file"
curl() {
  local current
  current=$(cat "$case2_counter_file")
  current=$((current + 1))
  echo "$current" >"$case2_counter_file"
  if [ "$current" -eq 1 ]; then
    echo "WORKER_LIMIT"
    return
  fi
  echo "event: done"
}

ORCH_MAX_ATTEMPTS=2 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "retry_then_success" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "case2 should succeed"
assert_request_id_trace 2 "req-2" "req-1" "req-2"
[ "${ORCH_LAST_RESULT:-}" = "success" ] || fail "case2 result mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "2/2" ] || fail "case2 attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "1" ] || fail "case2 retry count mismatch"

# Case 3: worker-limit exhausted on second attempt.
reset_uid_counter
request_ids=()
curl() {
  echo "WORKER_LIMIT"
}

ORCH_MAX_ATTEMPTS=2 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "retry_exhausted" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "case3 should fail"
assert_request_id_trace 2 "req-2" "req-1" "req-2"
[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "case3 result mismatch"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "worker_limit_exhausted" ] || fail "case3 reason mismatch"
[ "${ORCH_LAST_ATTEMPT:-}" = "2/2" ] || fail "case3 attempt mismatch"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "1" ] || fail "case3 retry count mismatch"

echo "live smoke retry request-id trace contract present"
