#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"

# Canonical reason constants must exist.
grep -q 'ORCH_RETRY_REASON_WORKER_LIMIT="WORKER_LIMIT"' "$helper"
grep -q 'ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED="worker_limit_exhausted"' "$helper"
grep -q 'ORCH_TERMINAL_REASON_DONE_EVENT_MISSING="done_event_missing"' "$helper"
grep -q 'ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING="cards_payload_missing"' "$helper"

# Retry log must use retry reason constant.
grep -q 'reason=${ORCH_RETRY_REASON_WORKER_LIMIT}' "$helper"

# Terminal reason assignments must use terminal constants.
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_DONE_EVENT_MISSING}"' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED}"' "$helper"
grep -q 'failure_reason="${ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING}"' "$helper"

# Terminal log must emit resolved failure_reason variable.
grep -q 'reason=${failure_reason}' "$helper"

echo "live smoke retry reason taxonomy contract present"
