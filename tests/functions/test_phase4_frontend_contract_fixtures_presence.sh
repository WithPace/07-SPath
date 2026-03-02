#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

f="docs/governance/PHASE-4-FRONTEND-CONTRACT-FIXTURES.md"
test -f "$f" || fail "missing phase4 frontend contract fixtures doc"

rg -q '^## Scope$' "$f" || fail "missing scope section"
rg -q '^## Fixture Set$' "$f" || fail "missing fixture set section"
rg -q '^## Validation Rules$' "$f" || fail "missing validation rules section"
rg -q '^## Consumption in Frontend CI$' "$f" || fail "missing frontend ci section"

rg -q 'chat-casual.*done payload' "$f" || fail "missing chat-casual done payload fixture"
rg -q 'assessment.*done payload' "$f" || fail "missing assessment done payload fixture"
rg -q 'training-advice.*done payload' "$f" || fail "missing training-advice done payload fixture"
rg -q 'training-record.*done payload' "$f" || fail "missing training-record done payload fixture"
rg -q 'dashboard.*delta payload' "$f" || fail "missing dashboard delta payload fixture"
rg -q 'retry.*transport_error' "$f" || fail "missing retry transport error fixture"

echo "phase4 frontend contract fixtures present"
