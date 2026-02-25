#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"

grep -q 'orchestrator retry: module=' "$helper"
grep -q 'request_id=${request_id}' "$helper"
grep -q 'attempt=${attempt}/${max_attempts}' "$helper"
grep -q 'sleep_seconds=${sleep_seconds}' "$helper"
grep -q 'reason=WORKER_LIMIT' "$helper"
grep -q 'orchestrator terminal_failure: module=' "$helper"
grep -q 'reason=${failure_reason}' "$helper"
grep -q 'failure_reason="worker_limit_exhausted"' "$helper"
grep -q 'failure_reason="done_event_missing"' "$helper"

echo "live smoke retry observability contract present"
