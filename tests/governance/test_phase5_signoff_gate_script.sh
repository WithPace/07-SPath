#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

gate_script="scripts/governance/check_phase5_signoff_gate.sh"
release_script="scripts/ci/release_go_live.sh"

test -f "$gate_script" || fail "missing phase5 signoff gate script"
test -x "$gate_script" || fail "phase5 signoff gate script must be executable"
rg -q 'REQUIRE_PHASE5_SIGNOFF' "$gate_script" \
  || fail "phase5 gate script must support REQUIRE_PHASE5_SIGNOFF"
rg -q 'PHASE-5-DELIVERY-CHECKLIST.md' "$gate_script" \
  || fail "phase5 gate script must read phase5 delivery checklist"
rg -q 'approved' "$gate_script" || fail "phase5 gate script must validate approved statuses"

test -f "$release_script" || fail "missing release go-live script"
rg -q 'REQUIRE_PHASE5_SIGNOFF' "$release_script" \
  || fail "release script must include REQUIRE_PHASE5_SIGNOFF handling"
rg -q 'scripts/governance/check_phase5_signoff_gate.sh' "$release_script" \
  || fail "release script must run phase5 signoff gate"

echo "phase5 signoff gate script present"
