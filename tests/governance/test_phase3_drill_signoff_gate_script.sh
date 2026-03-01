#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

gate_script="scripts/governance/check_phase3_drill_signoff_gate.sh"
release_script="scripts/ci/release_go_live.sh"

test -f "$gate_script" || fail "missing phase3 drill signoff gate script"
test -x "$gate_script" || fail "phase3 drill signoff gate script must be executable"
rg -q 'REQUIRE_PHASE3_DRILL_SIGNOFF' "$gate_script" \
  || fail "phase3 drill signoff gate script must support REQUIRE_PHASE3_DRILL_SIGNOFF"
rg -q 'PHASE-3-INCIDENT-DRILL-LOG.md' "$gate_script" \
  || fail "phase3 drill signoff gate script must read phase3 incident drill log"
rg -q 'PHASE-3-ROLLBACK-DRILL-LOG.md' "$gate_script" \
  || fail "phase3 drill signoff gate script must read phase3 rollback drill log"
rg -q 'approved' "$gate_script" || fail "phase3 drill signoff gate script must validate approved statuses"

test -f "$release_script" || fail "missing release go-live script"
rg -q 'scripts/governance/check_phase3_drill_signoff_gate.sh' "$release_script" \
  || fail "release script must run phase3 drill signoff gate script"

bash "$gate_script"

echo "phase3 drill signoff gate script present"
