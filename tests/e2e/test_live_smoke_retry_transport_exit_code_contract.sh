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

sleep() {
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
    echo "transport timeout" >&2
    return 28
  fi
  echo "event: done"
}

child_id="child-test"
access_token="token-test"
SUPABASE_URL="https://example.invalid"
SUPABASE_ANON_KEY="anon-test"
curl_common=(--silent)
request_ids=()

scenario_a_log=$(mktemp)
scenario_b_log=$(mktemp)

cleanup() {
  rm -f "$uid_counter_file" "$curl_counter_file" "$scenario_a_log" "$scenario_b_log"
}
trap cleanup EXIT

# Scenario A: one transport retry then success should include transport exit code in retry log.
reset_uid_counter
reset_curl_counter
request_ids=()
curl_fail_until=1
curl_always_fail=0

if ! ORCH_MAX_ATTEMPTS=4 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "transport_retry_log" "0" >/dev/null 2>"$scenario_a_log"; then
  fail "scenario_a should succeed after one transport retry"
fi

grep -q 'orchestrator retry: module=training request_id=req-1 attempt=1/4 sleep_seconds=1 reason=transport_error exit_code=28' "$scenario_a_log" || fail "scenario_a retry log missing transport exit code"

# Scenario B: transport exhausted should include exit code in terminal log and state marker.
reset_uid_counter
reset_curl_counter
request_ids=()
curl_fail_until=0
curl_always_fail=1

if ORCH_MAX_ATTEMPTS=3 ORCH_RETRY_BASE_DELAY_SECONDS=1 orchestrator_call_with_retry "training" "transport_terminal_log" "0" >/dev/null 2>"$scenario_b_log"; then
  fail "scenario_b should fail under transport exhaustion"
fi

grep -q 'orchestrator terminal_failure: module=training request_id=req-3 attempt=3/3 reason=transport_error_exhausted exit_code=28' "$scenario_b_log" || fail "scenario_b terminal log missing transport exit code"
case "${ORCH_LAST_RESPONSE:-}" in
  *transport_error_exit_code=28*)
    ;;
  *)
    fail "scenario_b ORCH_LAST_RESPONSE missing transport error marker"
    ;;
esac

echo "live smoke retry transport exit-code contract present"
