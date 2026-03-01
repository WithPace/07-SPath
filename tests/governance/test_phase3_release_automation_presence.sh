#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

f="docs/governance/PHASE-3-RELEASE-AUTOMATION.md"
test -f "$f" || fail "missing phase3 release automation doc"

rg -q '^## Canary Policy$' "$f" || fail "missing canary policy section"
rg -q '^## Rollback Trigger Matrix$' "$f" || fail "missing rollback trigger matrix section"
rg -q '^## Approval Gates$' "$f" || fail "missing approval gates section"
rg -q '^## Automated Verification Sequence$' "$f" || fail "missing automated verification sequence section"
rg -q '^## Release Evidence Log$' "$f" || fail "missing release evidence log section"
rg -q 'scripts/governance/check_phase3_drill_signoff_gate.sh' "$f" \
  || fail "phase3 release automation must include phase3 drill signoff gate command"

echo "phase3 release automation doc present"
