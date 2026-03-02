#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

incident_log="docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md"
rollback_log="docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md"

test -f "$incident_log" || fail "missing phase3 incident drill log"
test -f "$rollback_log" || fail "missing phase3 rollback drill log"

rg -q '^- \[x\] `docs/governance/PHASE-3-SLO-SLI-BASELINE.md` reviewed\.$' "$incident_log" \
  || fail "phase3 incident drill precondition not checked: SLO baseline reviewed"
rg -q '^- \[x\] `docs/governance/PHASE-3-OPERATIONS-RUNBOOK.md` reviewed\.$' "$incident_log" \
  || fail "phase3 incident drill precondition not checked: operations runbook reviewed"
rg -q '^- \[x\] on-call roles confirmed\.$' "$incident_log" \
  || fail "phase3 incident drill precondition not checked: on-call roles confirmed"
rg -q '^- \[x\] drill communication channel created\.$' "$incident_log" \
  || fail "phase3 incident drill precondition not checked: communication channel created"

rg -q '^- \[x\] rollback trigger selected from `PHASE-3-RELEASE-AUTOMATION.md`\.$' "$rollback_log" \
  || fail "phase3 rollback drill precondition not checked: rollback trigger selected"
rg -q '^- \[x\] last known good deployment revision identified\.$' "$rollback_log" \
  || fail "phase3 rollback drill precondition not checked: good revision identified"
rg -q '^- \[x\] release owner and operations owner present\.$' "$rollback_log" \
  || fail "phase3 rollback drill precondition not checked: owners present"
rg -q '^- \[x\] validation data retention and cleanup scope confirmed\.$' "$rollback_log" \
  || fail "phase3 rollback drill precondition not checked: retention scope confirmed"

echo "phase3 drill preconditions completion present"
