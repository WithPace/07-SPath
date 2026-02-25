#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"
grep -q "ORCH_MAX_ATTEMPTS" "$helper"
grep -q "ORCH_RETRY_BASE_DELAY_SECONDS" "$helper"
grep -q "WORKER_LIMIT" "$helper"
grep -q "1 << (attempt - 1)" "$helper"
grep -q 'sleep "$sleep_seconds"' "$helper"
grep -q 'request_ids+=("$request_id")' "$helper"
grep -q 'ORCH_LAST_REQUEST_ID="$request_id"' "$helper"
grep -q 'ORCH_LAST_RESPONSE="$response"' "$helper"

for f in \
  tests/e2e/test_orchestrator_chat_casual_live.sh \
  tests/e2e/test_orchestrator_assessment_training_live.sh \
  tests/e2e/test_orchestrator_training_live.sh \
  tests/e2e/test_orchestrator_training_record_live.sh \
  tests/e2e/test_orchestrator_dashboard_live.sh \
  tests/e2e/test_orchestrator_idempotency_live.sh

do
  test -f "$f"
  grep -q "_shared/orchestrator_retry.sh" "$f"
  grep -q "orchestrator_call_with_retry" "$f"
  grep -q -- "--retry 3" "$f"
  grep -q -- "--retry-delay 1" "$f"
  grep -q -- "--retry-all-errors" "$f"
done

echo "live smoke retry contract present (all scripts)"
