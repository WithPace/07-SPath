#!/usr/bin/env bash
set -euo pipefail

f="scripts/ci/final_gate.sh"
test -f "$f"
grep -q "build-contract.sh" "$f"
grep -q "verify-contract.sh" "$f"
grep -q "tests/db/\\*.sh" "$f"
grep -q "tests/functions/\\*.sh" "$f"
grep -q "tests/e2e/\\*.sh" "$f"
grep -q "tests/ci/\\*.sh" "$f"
echo "final gate script present"
