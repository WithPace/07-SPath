#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"

grep -q 'orchestrator retry: module=' "$helper"
grep -q 'request_id=${request_id}' "$helper"
grep -q 'attempt=${attempt}/${max_attempts}' "$helper"
grep -q 'sleep_seconds=${sleep_seconds}' "$helper"
grep -q 'reason=${ORCH_RETRY_REASON_WORKER_LIMIT}' "$helper"
grep -q 'reason=${ORCH_RETRY_REASON_TRANSPORT_ERROR}' "$helper"
grep -q 'orchestrator terminal_failure: module=' "$helper"
grep -q 'reason=${failure_reason}' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED}"' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_DONE_EVENT_MISSING}"' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING}"' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_TRANSPORT_ERROR_EXHAUSTED}"' "$helper"

echo "live smoke retry observability contract present"
