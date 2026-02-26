#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

checklist="docs/governance/PHASE-2-RELEASE-CHECKLIST.md"
drill_log="docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md"

test -f "$checklist" || fail "missing phase2 release checklist"
test -f "$drill_log" || fail "missing phase2 rollback drill log"

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

echo "phase2 release artifacts present"
