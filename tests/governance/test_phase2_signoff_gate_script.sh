#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

gate_script="scripts/governance/check_phase2_signoff_gate.sh"
release_script="scripts/ci/release_go_live.sh"

test -f "$gate_script" || fail "missing phase2 signoff gate script"
test -x "$gate_script" || fail "phase2 signoff gate script must be executable"
rg -q 'REQUIRE_FULL_SIGNOFF' "$gate_script" \
  || fail "signoff gate script must support REQUIRE_FULL_SIGNOFF"
rg -q 'PHASE-2-RELEASE-CHECKLIST.md' "$gate_script" \
  || fail "signoff gate script must read phase2 release checklist"
rg -q 'approved' "$gate_script" || fail "signoff gate script must validate approved statuses"

test -f "$release_script" || fail "missing release go-live script"
rg -q 'scripts/governance/check_phase2_signoff_gate.sh' "$release_script" \
  || fail "release script must run signoff gate script"

echo "phase2 signoff gate script present"
