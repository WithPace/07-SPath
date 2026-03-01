#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

log_file="docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md"
test -f "$log_file" || fail "missing phase2 rollback drill log"

rg -q '^\| engineering \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| approved \|$' "$log_file" \
  || fail "phase2 rollback engineering sign-off must be approved with UTC date"
rg -q '^\| operations \| [^|]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \| approved \|$' "$log_file" \
  || fail "phase2 rollback operations sign-off must be approved with UTC date"

echo "phase2 rollback drill sign-off completion present"
