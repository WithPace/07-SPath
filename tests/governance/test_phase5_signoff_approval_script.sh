#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/governance/approve_phase5_signoff.sh"

test -f "$script" || fail "missing phase5 signoff approval script"
test -x "$script" || fail "phase5 signoff approval script must be executable"

rg -q 'ROLE' "$script" || fail "script must require ROLE"
rg -q 'APPROVER' "$script" || fail "script must require APPROVER"
rg -q 'product\|operations\|security' "$script" || fail "script must validate role scope"
rg -q 'PHASE-5-DELIVERY-CHECKLIST.md' "$script" \
  || fail "script must update phase5 delivery checklist"
rg -q 'PHASE-5-RELEASE-RECORD.md' "$script" \
  || fail "script must update phase5 release record"
rg -q 'approved' "$script" || fail "script must set approved status"
rg -q 'DRY_RUN' "$script" || fail "script must support DRY_RUN mode"
rg -q 'approve_phase5_signoff.lock' "$script" || fail "script must use a dedicated lock file"
if ! rg -q 'flock -x' "$script" && ! rg -q 'LOCK_FILE\\.d' "$script"; then
  fail "script must guard concurrent writes via flock or lock-directory fallback"
fi

echo "phase5 signoff approval script present"
