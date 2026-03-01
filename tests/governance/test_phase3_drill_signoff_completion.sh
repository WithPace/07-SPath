#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

incident_form="docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md"
rollback_form="docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md"

test -f "$incident_form" || fail "missing phase3 incident drill form"
test -f "$rollback_form" || fail "missing phase3 rollback drill form"

check_approved_row() {
  local file="$1"
  local role="$2"
  rg -q "^\\| ${role} \\| [^|]+ \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| approved \\|$" "$file" \
    || fail "missing approved sign-off row role=${role} in ${file}"
}

check_approved_row "$incident_form" "engineering"
check_approved_row "$incident_form" "operations"
check_approved_row "$incident_form" "product operations"

check_approved_row "$rollback_form" "engineering"
check_approved_row "$rollback_form" "operations"
check_approved_row "$rollback_form" "release manager"

echo "phase3 drill sign-off completion present"
