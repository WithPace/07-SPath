#!/usr/bin/env bash
set -euo pipefail

f="tests/e2e/test_orchestrator_chat_casual_live.sh"
test -f "$f"
grep -q "cleanup()" "$f"
grep -q "trap cleanup EXIT" "$f"
grep -q "/auth/v1/admin/users/" "$f"
grep -q -- "-X DELETE" "$f"
echo "live smoke cleanup hooks present"
