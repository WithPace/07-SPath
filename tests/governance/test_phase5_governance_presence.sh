#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

checklist="docs/governance/PHASE-5-DELIVERY-CHECKLIST.md"
record="docs/governance/PHASE-5-RELEASE-RECORD.md"

test -f "$checklist" || fail "missing phase5 delivery checklist"
test -f "$record" || fail "missing phase5 release record"

rg -q '^## Scope$' "$checklist" || fail "missing scope section in phase5 checklist"
rg -q '^## Entry Criteria$' "$checklist" || fail "missing entry criteria section in phase5 checklist"
rg -q '^## Exit Criteria$' "$checklist" || fail "missing exit criteria section in phase5 checklist"
rg -q '^## Port Matrix$' "$checklist" || fail "missing port matrix section in phase5 checklist"
rg -q '^## Cross-Repo Sign-off$' "$checklist" || fail "missing cross-repo sign-off section in phase5 checklist"
rg -q '^## Risks and Controls$' "$checklist" || fail "missing risks and controls section in phase5 checklist"
rg -q 'scripts/ci/release_go_live.sh' "$checklist" || fail "phase5 checklist must reference backend strict go-live command"
rg -q 'scripts/ci/frontend_final_gate.sh' "$checklist" || fail "phase5 checklist must require frontend strict gate"
rg -q 'scripts/ci/admin_web_final_gate.sh' "$checklist" || fail "phase5 checklist must require admin web strict gate"

rg -q '^## Release Identity$' "$record" || fail "missing release identity section in phase5 record"
rg -q '^## Verification Evidence$' "$record" || fail "missing verification evidence section in phase5 record"
rg -q '^## Cross-Repo Handshake$' "$record" || fail "missing cross-repo handshake section in phase5 record"
rg -q '^## Rollback References$' "$record" || fail "missing rollback references section in phase5 record"
rg -q '\| phase \| Phase 5 \(Full Ports \+ Admin Web\) \|' "$record" || fail "phase5 release identity must include phase value"
rg -q '\| backend_commit_sha \| [0-9a-f]{7,40} \|' "$record" || fail "phase5 record must include backend commit sha evidence"
rg -q '\| frontend_commit_sha \| (PENDING|[0-9a-f]{7,40}) \|' "$record" || fail "phase5 record must include frontend commit sha or PENDING baseline marker"
rg -q '\| admin_web_commit_sha \| (PENDING|[0-9a-f]{7,40}) \|' "$record" || fail "phase5 record must include admin web commit sha or PENDING baseline marker"

echo "phase5 governance docs present"
