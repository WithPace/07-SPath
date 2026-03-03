#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export PATH="$REPO_ROOT/scripts/bin:$PATH"

CHECKLIST_FILE="docs/governance/PHASE-5-DELIVERY-CHECKLIST.md"
RECORD_FILE="docs/governance/PHASE-5-RELEASE-RECORD.md"
REQUIRE_PHASE5_SIGNOFF="${REQUIRE_PHASE5_SIGNOFF:-1}"

fail() {
  echo "$1" >&2
  exit 1
}

validate_mode() {
  case "$REQUIRE_PHASE5_SIGNOFF" in
    0|1) ;;
    *)
      fail "REQUIRE_PHASE5_SIGNOFF must be 0 or 1"
      ;;
  esac
}

get_checklist_status() {
  local role="$1"
  awk -F'|' -v role="$role" '
    /^## Cross-Repo Sign-off$/ { section = 1; next }
    /^## / && section == 1 { section = 0 }
    section == 1 && $0 ~ ("^\\| " role " \\|") {
      val = $5
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      print val
      exit
    }
  ' "$CHECKLIST_FILE"
}

require_approved_row() {
  local role="$1"
  rg -q "^\\| ${role} \\| [^|]+ \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| approved \\|$" "$CHECKLIST_FILE" \
    || fail "missing approved sign-off row role=${role}"
}

validate_optional_role() {
  local role="$1"
  local status
  status="$(get_checklist_status "$role")"
  [ -n "$status" ] || fail "missing sign-off row role=${role}"

  case "$status" in
    approved)
      require_approved_row "$role"
      ;;
    pending)
      [ "$REQUIRE_PHASE5_SIGNOFF" = "0" ] || fail "role=${role} is pending while REQUIRE_PHASE5_SIGNOFF=1"
      ;;
    *)
      fail "role=${role} has invalid status=${status}"
      ;;
  esac
}

check_record_integrated_status() {
  local expected="$1"
  local status
  status="$(awk -F'|' '/^\| integrated sign-off complete \|/ {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3; exit}' "$RECORD_FILE")"
  [ -n "$status" ] || fail "missing integrated sign-off checkpoint row in ${RECORD_FILE}"
  [ "$status" = "$expected" ] || fail "integrated sign-off complete must be ${expected}, got ${status}"
}

validate_mode
test -f "$CHECKLIST_FILE" || fail "missing ${CHECKLIST_FILE}"
test -f "$RECORD_FILE" || fail "missing ${RECORD_FILE}"

require_approved_row "backend engineering"
require_approved_row "frontend engineering"
require_approved_row "admin web engineering"

validate_optional_role "product"
validate_optional_role "operations"
validate_optional_role "security"

if [ "$REQUIRE_PHASE5_SIGNOFF" = "1" ]; then
  check_record_integrated_status "done"
else
  # relaxed mode allows pending/done in release record.
  if ! rg -q '^\| integrated sign-off complete \| (done|pending) \|' "$RECORD_FILE"; then
    fail "integrated sign-off checkpoint must be done or pending in relaxed mode"
  fi
fi

echo "phase5 sign-off gate pass (require_phase5_signoff=${REQUIRE_PHASE5_SIGNOFF})"
