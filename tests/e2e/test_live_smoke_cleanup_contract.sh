#!/usr/bin/env bash
set -euo pipefail

for f in \
  tests/e2e/test_orchestrator_chat_casual_live.sh \
  tests/e2e/test_orchestrator_assessment_training_live.sh \
  tests/e2e/test_orchestrator_training_live.sh \
  tests/e2e/test_orchestrator_training_record_live.sh \
  tests/e2e/test_orchestrator_dashboard_live.sh \
  tests/e2e/test_orchestrator_idempotency_live.sh

do
  test -f "$f"
  grep -q "cleanup()" "$f"
  grep -q "trap cleanup EXIT" "$f"
  grep -q "/auth/v1/admin/users/" "$f"
  grep -q -- "-X DELETE" "$f"
done

echo "live smoke cleanup contract present (all scripts)"
