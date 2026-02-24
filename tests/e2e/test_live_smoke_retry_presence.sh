#!/usr/bin/env bash
set -euo pipefail

f="tests/e2e/test_orchestrator_chat_casual_live.sh"
test -f "$f"
grep -q "WORKER_LIMIT" "$f"
grep -q "max_attempts" "$f"
grep -q "for attempt in" "$f"
echo "live smoke retry hooks present"
