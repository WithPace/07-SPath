#!/usr/bin/env bash
set -euo pipefail

f="docs/governance/REBUILD-VERIFICATION-2026-02-23.md"
test -f "$f"
grep -q "scripts/ci/final_gate.sh" "$f"
if grep -q "/tmp/final_gate.sh" "$f"; then
  echo "rebuild verification should not depend on /tmp path" >&2
  exit 1
fi
echo "rebuild verification is reproducible"
