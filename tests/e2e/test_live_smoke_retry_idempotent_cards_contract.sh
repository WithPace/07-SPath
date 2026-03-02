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

# idempotent response without cards should be treated as success.
curl() {
  printf 'event: done\ndata: {"request_id":"req-1","idempotent":true}\n'
}

log_file=$(mktemp)
trap 'rm -f "$uid_counter_file" "$log_file"' EXIT

ORCH_MAX_ATTEMPTS=2 orchestrator_call_with_retry "dashboard" "idempotent_no_cards" "1" >/dev/null 2>"$log_file"
rc=$?

[ "$rc" -eq 0 ] || fail "idempotent cards-missing case should pass"
[ "${ORCH_LAST_RESULT:-}" = "success" ] || fail "idempotent cards-missing case wrong result"
[ "${ORCH_LAST_FAILURE_REASON:-}" = "" ] || fail "idempotent cards-missing case should not set failure reason"
[ "${ORCH_LAST_ATTEMPT:-}" = "1/2" ] || fail "idempotent cards-missing case wrong attempt"
[ "${ORCH_LAST_RETRY_COUNT:-}" = "0" ] || fail "idempotent cards-missing case retry count should be 0"

if grep -q 'orchestrator terminal_failure:' "$log_file"; then
  fail "idempotent cards-missing case must not emit terminal_failure log"
fi

echo "live smoke retry idempotent cards contract present"
