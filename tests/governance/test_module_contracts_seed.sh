#!/usr/bin/env bash
set -euo pipefail
for m in orchestrator assessment training dashboard; do
  f="governance/agent-contract/modules/$m/contract.yaml"
  test -f "$f"
  grep -q "^module: $m$" "$f"
  grep -q -- "- audit" "$f"
  grep -q -- "- optimize" "$f"
  grep -q -- "- fill_gap" "$f"
done
echo "module contracts exist"
