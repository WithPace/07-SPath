#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/governance/approve_phase3_drill_signoff.sh"

test -f "$script" || fail "missing phase3 drill signoff script"
test -x "$script" || fail "phase3 drill signoff script must be executable"

rg -q 'FORM' "$script" || fail "script must require FORM"
rg -q 'ROLE' "$script" || fail "script must require ROLE"
rg -q 'APPROVER' "$script" || fail "script must require APPROVER"
rg -q 'incident\|rollback' "$script" || fail "script must validate incident/rollback form scope"
rg -q 'product operations' "$script" || fail "script must support incident product operations role"
rg -q 'release manager' "$script" || fail "script must support rollback release manager role"
rg -q 'DRY_RUN' "$script" || fail "script must support DRY_RUN mode"
rg -q 'approve_phase3_drill_signoff.lock' "$script" || fail "script must use dedicated lock file"
if ! rg -q 'flock -x' "$script" && ! rg -q 'LOCK_FILE\\.d' "$script"; then
  fail "script must guard concurrent writes via flock or lock-directory fallback"
fi

echo "phase3 drill signoff script present"
