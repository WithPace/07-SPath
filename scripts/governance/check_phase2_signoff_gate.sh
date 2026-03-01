#!/usr/bin/env bash
set -euo pipefail

CHECKLIST_FILE="docs/governance/PHASE-2-RELEASE-CHECKLIST.md"
REQUIRE_FULL_SIGNOFF="${REQUIRE_FULL_SIGNOFF:-0}"

fail() {
  echo "$1" >&2
  exit 1
}

test -f "$CHECKLIST_FILE" || fail "missing ${CHECKLIST_FILE}"

get_signoff_field() {
  local role="$1"
  local field="$2"
  awk -F'|' -v role="$role" -v field="$field" '
    /^## Sign-off$/ { section = 1; next }
    /^## / && section == 1 { section = 0 }
    section == 1 && $0 ~ ("^\\| " role " \\|") {
      val = $field
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      print val
      exit
    }
  ' "$CHECKLIST_FILE"
}

has_pending_control() {
  local role="$1"
  rg -q "^\\| ${role} \\| [^|]+ \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\|$" \
    "$CHECKLIST_FILE"
}

validate_row() {
  local role="$1"
  local approver
  local date_utc
  local status

  approver="$(get_signoff_field "$role" 3)"
  date_utc="$(get_signoff_field "$role" 4)"
  status="$(get_signoff_field "$role" 5)"

  [ -n "$status" ] || fail "missing sign-off row for role=${role}"

  if [ "$status" = "approved" ]; then
    [ -n "$approver" ] || fail "approved role=${role} missing approver"
    [ -n "$date_utc" ] || fail "approved role=${role} missing date_utc"
    if ! [[ "$date_utc" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
      fail "approved role=${role} has invalid date_utc format"
    fi
  elif [ "$status" = "pending" ]; then
    if [ "$REQUIRE_FULL_SIGNOFF" = "1" ]; then
      fail "role=${role} is pending while REQUIRE_FULL_SIGNOFF=1"
    fi
    has_pending_control "$role" || fail "role=${role} pending without pending-signoff-control row"
  else
    fail "role=${role} has invalid status=${status}"
  fi
}

validate_row "engineering"
engineering_status="$(get_signoff_field engineering 5)"
[ "$engineering_status" = "approved" ] || fail "engineering must be approved"

validate_row "product"
validate_row "operations"

echo "phase2 sign-off gate pass (require_full_signoff=${REQUIRE_FULL_SIGNOFF})"
