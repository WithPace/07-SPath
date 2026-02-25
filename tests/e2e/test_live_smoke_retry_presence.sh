#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"
grep -q "WORKER_LIMIT" "$helper"
grep -q "1 << (attempt - 1)" "$helper"

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
done

echo "live smoke retry hooks present (shared)"
