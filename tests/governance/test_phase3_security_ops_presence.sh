#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

f="docs/governance/PHASE-3-SECURITY-OPERATIONS.md"
test -f "$f" || fail "missing phase3 security operations doc"

rg -q '^## Secrets Rotation Policy$' "$f" || fail "missing secrets rotation section"
rg -q '^## Privileged Action Controls$' "$f" || fail "missing privileged action controls section"
rg -q '^## Access Review Cadence$' "$f" || fail "missing access review cadence section"
rg -q '^## Audit Evidence Requirements$' "$f" || fail "missing audit evidence requirements section"
rg -q '^## Incident Security Response$' "$f" || fail "missing incident security response section"

echo "phase3 security operations doc present"
