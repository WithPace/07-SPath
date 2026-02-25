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
  rm -f "$uid_counter_file"
}
trap cleanup EXIT

# Case 1: success should clear stale state and keep retry count at 0.
ORCH_LAST_RESULT="stale"
ORCH_LAST_FAILURE_REASON="stale"
ORCH_LAST_ATTEMPT="stale"
ORCH_LAST_RETRY_COUNT="99"
ORCH_LAST_REQUEST_ID="stale"
ORCH_LAST_RESPONSE="stale"

curl() {
  echo "event: done"
}

ORCH_MAX_ATTEMPTS=2 orchestrator_call_with_retry "training" "ok" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "success case returned non-zero"
[ "${ORCH_LAST_RESULT:-}" = "success" ] || fail "success case wrong result"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "" ] || fail "success case failure reason not cleared"
[ "${ORCH_LAST_ATTEMPT:-}" = "1/2" ] || fail "success case attempt wrong"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "0" ] || fail "success case retry count should be 0"

# Case 2: worker-limit exhausted should set failure state and retry count 1.
ORCH_LAST_RESULT="stale"
ORCH_LAST_FAILURE_REASON="stale"
ORCH_LAST_ATTEMPT="stale"
ORCH_LAST_RETRY_COUNT="99"

curl() {
  echo "WORKER_LIMIT"
}

ORCH_MAX_ATTEMPTS=2 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "limit" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "worker-limit case should fail"
[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "worker-limit case wrong result"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "worker_limit_exhausted" ] || fail "worker-limit case wrong reason"
[ "${ORCH_LAST_ATTEMPT:-}" = "2/2" ] || fail "worker-limit case attempt wrong"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "1" ] || fail "worker-limit case retry count should be 1"

# Case 3: done-event-missing should reset and keep retry count 0.
ORCH_LAST_RESULT="stale"
ORCH_LAST_FAILURE_REASON="stale"
ORCH_LAST_ATTEMPT="stale"
ORCH_LAST_RETRY_COUNT="99"

curl() {
  echo "unexpected payload"
}

ORCH_MAX_ATTEMPTS=2 orchestrator_call_with_retry "training" "missing_done" "0" >/dev/null 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "done-event-missing case should fail"
[ "${ORCH_LAST_RESULT:-}" = "failure" ] || fail "done-event-missing case wrong result"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "done_event_missing" ] || fail "done-event-missing case wrong reason"
[ "${ORCH_LAST_ATTEMPT:-}" = "1/2" ] || fail "done-event-missing case attempt wrong"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "0" ] || fail "done-event-missing case retry count should be 0"

echo "live smoke retry state reset contract present"
