#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/governance/update_phase2_release_record.sh"
release_script="scripts/ci/release_go_live.sh"
record="docs/governance/PHASE-2-RELEASE-RECORD.md"

test -f "$script" || fail "missing phase2 release record update script"
test -x "$script" || fail "phase2 release record update script must be executable"
test -f "$record" || fail "missing phase2 release record doc"
test -f "$release_script" || fail "missing release go-live script"

rg -q 'PHASE-2-RELEASE-RECORD.md' "$script" || fail "release record update script must target phase2 release record"
rg -q 'DRY_RUN' "$script" || fail "release record update script must support DRY_RUN"
rg -q 'COMMIT_SHA' "$script" || fail "release record update script must support commit sha input"
rg -q 'RELEASE_OPERATOR' "$script" || fail "release record update script must support release operator input"
rg -q 'DATE_UTC' "$script" || fail "release record update script must support executed_at_utc input"
if ! rg -q 'flock -x' "$script" && ! rg -q 'LOCK_FILE\\.d' "$script"; then
  fail "release record update script must guard concurrent writes via flock or lock-directory fallback"
fi

rg -q 'bash scripts/governance/update_phase2_release_record.sh' "$release_script" \
  || fail "release go-live script must invoke release record update script"

DRY_RUN=1 RELEASE_OPERATOR='release-operator-ci' COMMIT_SHA='123abc456def' DATE_UTC='2026-03-01T00:00:00Z' bash "$script" >/dev/null

echo "phase2 release record update script present"
