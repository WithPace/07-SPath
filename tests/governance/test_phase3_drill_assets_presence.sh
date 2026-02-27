#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

incident_script="scripts/ops/run_phase3_incident_drill.sh"
rollback_script="scripts/ops/run_phase3_rollback_drill.sh"
incident_form="docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md"
rollback_form="docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md"
runbook="docs/governance/PHASE-3-OPERATIONS-RUNBOOK.md"
release_doc="docs/governance/PHASE-3-RELEASE-AUTOMATION.md"

test -f "$incident_script" || fail "missing phase3 incident drill script"
test -f "$rollback_script" || fail "missing phase3 rollback drill script"
test -x "$incident_script" || fail "incident drill script must be executable"
test -x "$rollback_script" || fail "rollback drill script must be executable"

test -f "$incident_form" || fail "missing phase3 incident drill form"
test -f "$rollback_form" || fail "missing phase3 rollback drill form"

for f in "$incident_form" "$rollback_form"; do
  rg -q '^## Drill Metadata$' "$f" || fail "missing Drill Metadata in $f"
  rg -q '^## Preconditions$' "$f" || fail "missing Preconditions in $f"
  rg -q '^## Command Evidence$' "$f" || fail "missing Command Evidence in $f"
  rg -q '^## Outcome$' "$f" || fail "missing Outcome in $f"
  rg -q '^## Sign-off$' "$f" || fail "missing Sign-off in $f"
done

rg -q 'DRY_RUN' "$incident_script" || fail "incident drill script missing DRY_RUN support"
rg -q 'DRY_RUN' "$rollback_script" || fail "rollback drill script missing DRY_RUN support"
rg -q 'tests/governance/test_docs_presence.sh' "$incident_script" || fail "incident drill missing docs gate check"
rg -q 'tests/governance/test_e2e_governance.sh' "$incident_script" || fail "incident drill missing e2e governance check"
rg -q 'scripts/ci/final_gate.sh' "$rollback_script" || fail "rollback drill missing final gate check"
rg -q 'tests/e2e/test_phase2_parent_weekly_journey_live.sh' "$rollback_script" || fail "rollback drill missing phase2 weekly scenario check"
rg -q 'ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS' "$rollback_script" || fail "rollback drill missing final gate retry attempts config"
rg -q 'ROLLBACK_DRILL_FINAL_GATE_RETRY_DELAY_SECONDS' "$rollback_script" || fail "rollback drill missing final gate retry delay config"
rg -q 'final_gate retry:' "$rollback_script" || fail "rollback drill missing final gate retry log"

rg -q 'scripts/ops/run_phase3_incident_drill.sh' "$runbook" || fail "runbook missing incident drill script reference"
rg -q 'scripts/ops/run_phase3_rollback_drill.sh' "$runbook" || fail "runbook missing rollback drill script reference"
rg -q 'docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md' "$release_doc" || fail "release automation missing incident form reference"
rg -q 'docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md' "$release_doc" || fail "release automation missing rollback form reference"

echo "phase3 drill assets present"
