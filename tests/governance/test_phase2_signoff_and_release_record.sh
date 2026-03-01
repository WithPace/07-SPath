#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

checklist="docs/governance/PHASE-2-RELEASE-CHECKLIST.md"
record="docs/governance/PHASE-2-RELEASE-RECORD.md"

test -f "$checklist" || fail "missing phase2 release checklist"
test -f "$record" || fail "missing phase2 release record"

rg -q '^## Sign-off$' "$checklist" || fail "missing sign-off section"
rg -q '^| engineering \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| approved \|$' "$checklist" \
  || fail "engineering sign-off must be approved with concrete approver and UTC date"

rg -q '^## Release Identity$' "$record" || fail "missing release identity section"
rg -q '^## Verification Evidence$' "$record" || fail "missing verification evidence section"
rg -q '^## Rollback References$' "$record" || fail "missing rollback references section"
rg -q 'bash scripts/ci/release_go_live.sh' "$record" || fail "release record missing go-live command evidence"
rg -q '\| commit_sha \| [0-9a-f]{7,40} \|' "$record" || fail "release record missing commit sha evidence"

echo "phase2 sign-off and release record present"
