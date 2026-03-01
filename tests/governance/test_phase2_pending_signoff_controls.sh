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
rg -q '^\| product \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \|$' "$checklist" \
  || fail "product pending control must include blocker and target/escalation UTC timestamps"
rg -q '^\| operations \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \|$' "$checklist" \
  || fail "operations pending control must include blocker and target/escalation UTC timestamps"

rg -q '^## Sign-off Snapshot$' "$record" \
  || fail "missing sign-off snapshot section in release record"

release_status="$(awk -F'|' '/^\| status \|/ {gsub(/ /, "", $3); print $3; exit}' "$checklist")"

if [ "$release_status" = "fully_approved" ]; then
  rg -q '^\| product \| [^|]+ \| approved \|$' "$record" \
    || fail "fully_approved release must have product approved snapshot row"
  rg -q '^\| operations \| [^|]+ \| approved \|$' "$record" \
    || fail "fully_approved release must have operations approved snapshot row"
else
  rg -q '^\| product \| [^|]+ \| (pending|approved) \|$' "$record" \
    || fail "release record missing product snapshot row"
  rg -q '^\| operations \| [^|]+ \| (pending|approved) \|$' "$record" \
    || fail "release record missing operations snapshot row"
fi

echo "phase2 pending sign-off controls present"
