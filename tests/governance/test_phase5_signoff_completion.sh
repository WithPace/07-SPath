#!/usr/bin/env bash
set -euo pipefail

file="docs/governance/PHASE-5-DELIVERY-CHECKLIST.md"

fail() {
  echo "$1" >&2
  exit 1
}

test -f "$file" || fail "missing phase5 delivery checklist"

check_approved_row() {
  local role="$1"
  rg -q "^\\| ${role} \\| [^|]+ \\| [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| approved \\|$" "$file" \
    || fail "missing approved sign-off row role=${role}"
}

check_approved_row "backend engineering"
check_approved_row "frontend engineering"
check_approved_row "admin web engineering"
check_approved_row "product"
check_approved_row "operations"
check_approved_row "security"

echo "phase5 sign-off completion present"
