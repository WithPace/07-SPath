#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

checklist="docs/governance/PHASE-2-RELEASE-CHECKLIST.md"
drill_log="docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md"
drill_script="scripts/ops/run_phase2_rollback_drill.sh"

test -f "$checklist" || fail "missing phase2 release checklist"
test -f "$drill_log" || fail "missing phase2 rollback drill log"
test -f "$drill_script" || fail "missing phase2 rollback drill script"

rg -q '^## Entry Criteria$' "$checklist" || fail "missing entry criteria section"
rg -q '^## Exit Criteria$' "$checklist" || fail "missing exit criteria section"
rg -q '^## Rollback Trigger$' "$checklist" || fail "missing rollback trigger section"
rg -q '^## Sign-off$' "$checklist" || fail "missing sign-off section"
rg -q 'tests/governance/test_phase2_release_artifacts.sh' "$checklist" \
  || fail "release checklist missing phase2 artifact gate command"
rg -q 'bash scripts/ci/final_gate.sh' "$checklist" \
  || fail "release checklist missing final gate command"

rg -q '^## Drill Metadata$' "$drill_log" || fail "missing drill metadata section"
rg -q '^## Command Evidence$' "$drill_log" || fail "missing command evidence section"
rg -q '^## Outcome$' "$drill_log" || fail "missing outcome section"
rg -q 'supabase functions deploy <module>' "$drill_log" \
  || fail "missing rollback deploy command template"
rg -q 'bash scripts/ci/final_gate.sh' "$drill_log" \
  || fail "missing post-rollback final gate validation"
rg -q '^## Execution Record: phase2-rollback-drill-001-' "$drill_log" \
  || fail "missing phase2 rollback execution record evidence"

rg -q 'tests/e2e/test_phase2_parent_weekly_journey_live.sh' "$drill_script" \
  || fail "phase2 rollback drill missing weekly scenario check"
rg -q 'tests/e2e/test_phase2_parent_dashboard_followup_live.sh' "$drill_script" \
  || fail "phase2 rollback drill missing followup scenario check"
rg -q 'scripts/ci/final_gate.sh' "$drill_script" \
  || fail "phase2 rollback drill missing final gate command"
rg -q 'ROLLBACK_DRILL_RUN_FINAL_GATE' "$drill_script" \
  || fail "phase2 rollback drill missing final gate mode switch"
rg -q '\| ended_at_utc \|' "$drill_script" \
  || fail "phase2 rollback drill missing ended_at_utc evidence field"
rg -q '\| elapsed_seconds \|' "$drill_script" \
  || fail "phase2 rollback drill missing elapsed_seconds evidence field"
rg -q 'tests/governance/test_docs_presence.sh' "$drill_script" \
  || fail "phase2 rollback drill missing docs presence check"
rg -q 'tests/governance/test_e2e_governance.sh' "$drill_script" \
  || fail "phase2 rollback drill missing e2e governance check"

echo "phase2 release artifacts present"
