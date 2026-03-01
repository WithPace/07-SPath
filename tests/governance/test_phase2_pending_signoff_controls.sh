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

rg -q '^## Pending Sign-off Controls$' "$checklist" \
  || fail "missing pending sign-off controls section"
rg -q '^| product \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \|$' "$checklist" \
  || fail "product pending control must include blocker and target/escalation UTC timestamps"
rg -q '^| operations \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \|$' "$checklist" \
  || fail "operations pending control must include blocker and target/escalation UTC timestamps"

rg -q '^## Sign-off Snapshot$' "$record" \
  || fail "missing sign-off snapshot section in release record"
rg -q '^| product \| [^|]+ \| pending \|' "$record" \
  || fail "release record missing product pending snapshot row"
rg -q '^| operations \| [^|]+ \| pending \|' "$record" \
  || fail "release record missing operations pending snapshot row"

echo "phase2 pending sign-off controls present"
