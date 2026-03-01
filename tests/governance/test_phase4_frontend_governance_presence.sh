#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

checklist="docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md"
record="docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md"

test -f "$checklist" || fail "missing phase4 frontend delivery checklist"
test -f "$record" || fail "missing phase4 frontend release record"

rg -q '^## Scope$' "$checklist" || fail "missing scope section in phase4 checklist"
rg -q '^## Entry Criteria$' "$checklist" || fail "missing entry criteria section in phase4 checklist"
rg -q '^## Exit Criteria$' "$checklist" || fail "missing exit criteria section in phase4 checklist"
rg -q '^## Cross-Repo Sign-off$' "$checklist" || fail "missing cross-repo sign-off section in phase4 checklist"
rg -q 'frontend_final_gate' "$checklist" || fail "phase4 checklist must require frontend final gate"
rg -q 'scripts/ci/release_go_live.sh' "$checklist" || fail "phase4 checklist must reference backend strict go-live command"

rg -q '^## Release Identity$' "$record" || fail "missing release identity section in phase4 record"
rg -q '^## Verification Evidence$' "$record" || fail "missing verification evidence section in phase4 record"
rg -q '^## Cross-Repo Handshake$' "$record" || fail "missing cross-repo handshake section in phase4 record"
rg -q '^## Rollback References$' "$record" || fail "missing rollback references section in phase4 record"
rg -q '\| frontend_commit_sha \| [0-9a-f]{7,40} \|' "$record" || fail "phase4 record must include frontend commit sha evidence"
rg -q '\| backend_commit_sha \| [0-9a-f]{7,40} \|' "$record" || fail "phase4 record must include backend commit sha evidence"

echo "phase4 frontend governance docs present"
