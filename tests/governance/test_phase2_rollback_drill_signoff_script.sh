#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/governance/approve_phase2_rollback_drill_signoff.sh"

test -f "$script" || fail "missing phase2 rollback drill signoff script"
test -x "$script" || fail "phase2 rollback drill signoff script must be executable"
rg -q 'ROLE' "$script" || fail "script must require ROLE"
rg -q 'APPROVER' "$script" || fail "script must require APPROVER"
rg -q 'engineering\|operations' "$script" || fail "script must validate role scope"
rg -q 'PHASE-2-ROLLBACK-DRILL-LOG.md' "$script" || fail "script must update phase2 rollback drill log"
rg -q 'DRY_RUN' "$script" || fail "script must support DRY_RUN mode"
rg -q 'approve_phase2_rollback_drill_signoff.lock' "$script" || fail "script must use dedicated lock file"
if ! rg -q 'flock -x' "$script" && ! rg -q 'LOCK_FILE\\.d' "$script"; then
  fail "script must guard concurrent writes via flock or lock-directory fallback"
fi

echo "phase2 rollback drill signoff script present"
