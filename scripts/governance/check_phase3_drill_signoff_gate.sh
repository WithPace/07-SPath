#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export PATH="$REPO_ROOT/scripts/bin:$PATH"

REQUIRE_PHASE3_DRILL_SIGNOFF="${REQUIRE_PHASE3_DRILL_SIGNOFF:-1}"

incident_form="docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md"
rollback_form="docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md"

fail() {
  echo "$1" >&2
  exit 1
}

validate_mode() {
  case "$REQUIRE_PHASE3_DRILL_SIGNOFF" in
    0|1) ;;
    *)
      fail "REQUIRE_PHASE3_DRILL_SIGNOFF must be 0 or 1"
      ;;
  esac
}

check_approved_row() {
  local file="$1"
  local role="$2"
  rg -q "^\\| ${role} \\| [^|]+ \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| approved \\|$" "$file" \
    || fail "missing approved sign-off row role=${role} in ${file}"
}

validate_mode

if [ "$REQUIRE_PHASE3_DRILL_SIGNOFF" = "0" ]; then
  echo "phase3 drill sign-off gate skipped (require_phase3_drill_signoff=0)"
  exit 0
fi

test -f "$incident_form" || fail "missing ${incident_form}"
test -f "$rollback_form" || fail "missing ${rollback_form}"

check_approved_row "$incident_form" "engineering"
check_approved_row "$incident_form" "operations"
check_approved_row "$incident_form" "product operations"

check_approved_row "$rollback_form" "engineering"
check_approved_row "$rollback_form" "operations"
check_approved_row "$rollback_form" "release manager"

echo "phase3 drill sign-off gate pass (require_phase3_drill_signoff=${REQUIRE_PHASE3_DRILL_SIGNOFF})"
