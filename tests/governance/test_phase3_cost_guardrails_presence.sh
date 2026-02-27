#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

f="docs/governance/PHASE-3-COST-GUARDRAILS.md"
test -f "$f" || fail "missing phase3 cost guardrails doc"

rg -q '^## Budget Thresholds$' "$f" || fail "missing budget thresholds section"
rg -q '^## Spend Anomaly Response$' "$f" || fail "missing spend anomaly response section"
rg -q '^## Capacity Ceilings$' "$f" || fail "missing capacity ceilings section"
rg -q '^## CI Enforcement$' "$f" || fail "missing ci enforcement section"
rg -q '^## Review Cadence$' "$f" || fail "missing review cadence section"

echo "phase3 cost guardrails doc present"
