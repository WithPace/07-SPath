#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

slo_file="docs/governance/PHASE-3-SLO-SLI-BASELINE.md"
runbook_file="docs/governance/PHASE-3-OPERATIONS-RUNBOOK.md"

test -f "$slo_file" || fail "missing phase3 slo/sli baseline"
test -f "$runbook_file" || fail "missing phase3 operations runbook"

rg -q '^## SLO Targets$' "$slo_file" || fail "missing SLO targets section"
rg -q '^## SLI Measurements$' "$slo_file" || fail "missing SLI measurements section"
rg -q '^## Alert Thresholds$' "$slo_file" || fail "missing alert thresholds section"
rg -q '^## Ownership$' "$slo_file" || fail "missing ownership section"

rg -q '^## Incident Severity Matrix$' "$runbook_file" || fail "missing severity matrix section"
rg -q '^## Incident Response Workflow$' "$runbook_file" || fail "missing incident response workflow section"
rg -q '^## On-call Escalation$' "$runbook_file" || fail "missing escalation section"
rg -q '^## Drill Evidence$' "$runbook_file" || fail "missing drill evidence section"

echo "phase3 slo/runbook docs present"
