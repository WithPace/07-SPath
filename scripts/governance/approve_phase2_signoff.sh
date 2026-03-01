#!/usr/bin/env bash
set -euo pipefail

ROLE="${ROLE:-}"
APPROVER="${APPROVER:-}"
DATE_UTC="${DATE_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
DRY_RUN="${DRY_RUN:-0}"

CHECKLIST_FILE="docs/governance/PHASE-2-RELEASE-CHECKLIST.md"
RECORD_FILE="docs/governance/PHASE-2-RELEASE-RECORD.md"

fail() {
  echo "$1" >&2
  exit 1
}

validate_inputs() {
  case "$ROLE" in
    product|operations) ;;
    *)
      fail "ROLE must be one of: product|operations"
      ;;
  esac

  if [ -z "$APPROVER" ]; then
    fail "APPROVER is required"
  fi

  if [[ "$APPROVER" == *"|"* ]]; then
    fail "APPROVER must not contain '|'"
  fi

  if ! [[ "$DATE_UTC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    fail "DATE_UTC must match YYYY-MM-DDTHH:MM:SSZ"
  fi

  test -f "$CHECKLIST_FILE" || fail "missing $CHECKLIST_FILE"
  test -f "$RECORD_FILE" || fail "missing $RECORD_FILE"
}

update_checklist_rows() {
  local in_file="$1"
  local out_file="$2"
  awk -v role="$ROLE" -v approver="$APPROVER" -v date_utc="$DATE_UTC" '
    /^## Sign-off$/ { section = "signoff"; print; next }
    /^## Pending Sign-off Controls$/ { section = "pending"; print; next }
    /^## / && $0 != "## Sign-off" && $0 != "## Pending Sign-off Controls" { section = "other"; print; next }
    {
      if (section == "signoff" && $0 ~ ("^\\| " role " \\|")) {
        print "| " role " | " approver " | " date_utc " | approved |"
        next
      }
      if (section == "pending" && $0 ~ ("^\\| " role " \\|")) {
        print "| " role " | approved by " approver " | " date_utc " | " date_utc " |"
        next
      }
      print
    }
  ' "$in_file" >"$out_file"
}

derive_release_status() {
  local file="$1"
  local product_status
  local operations_status

  product_status="$(awk -F'|' '/^\| product \|/ {gsub(/ /, "", $5); print $5; exit}' "$file")"
  operations_status="$(awk -F'|' '/^\| operations \|/ {gsub(/ /, "", $5); print $5; exit}' "$file")"

  if [ "$product_status" = "approved" ] && [ "$operations_status" = "approved" ]; then
    echo "fully_approved"
    return
  fi
  if [ "$product_status" = "approved" ] && [ "$operations_status" != "approved" ]; then
    echo "engineering_product_approved_pending_operations"
    return
  fi
  if [ "$operations_status" = "approved" ] && [ "$product_status" != "approved" ]; then
    echo "engineering_operations_approved_pending_product"
    return
  fi
  echo "engineering_approved_pending_product_ops"
}

update_release_status_line() {
  local in_file="$1"
  local out_file="$2"
  local status_value="$3"
  awk -v status_value="$status_value" '
    {
      if ($0 ~ /^\| status \|/) {
        print "| status | " status_value " |"
        next
      }
      print
    }
  ' "$in_file" >"$out_file"
}

update_record_snapshot() {
  local in_file="$1"
  local out_file="$2"
  awk -v role="$ROLE" -v approver="$APPROVER" '
    /^## Sign-off Snapshot$/ { section = "snapshot"; print; next }
    /^## / && $0 != "## Sign-off Snapshot" { section = "other"; print; next }
    {
      if (section == "snapshot" && $0 ~ ("^\\| " role " \\|")) {
        print "| " role " | " approver " | approved |"
        next
      }
      print
    }
  ' "$in_file" >"$out_file"
}

validate_inputs

tmp_checklist_1="$(mktemp)"
tmp_checklist_2="$(mktemp)"
tmp_record_1="$(mktemp)"

trap 'rm -f "$tmp_checklist_1" "$tmp_checklist_2" "$tmp_record_1"' EXIT

update_checklist_rows "$CHECKLIST_FILE" "$tmp_checklist_1"
new_release_status="$(derive_release_status "$tmp_checklist_1")"
update_release_status_line "$tmp_checklist_1" "$tmp_checklist_2" "$new_release_status"
update_record_snapshot "$RECORD_FILE" "$tmp_record_1"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY_RUN] diff for ${CHECKLIST_FILE}"
  diff -u "$CHECKLIST_FILE" "$tmp_checklist_2" || true
  echo "[DRY_RUN] diff for ${RECORD_FILE}"
  diff -u "$RECORD_FILE" "$tmp_record_1" || true
  exit 0
fi

cp "$tmp_checklist_2" "$CHECKLIST_FILE"
cp "$tmp_record_1" "$RECORD_FILE"

echo "updated sign-off approval for role=${ROLE} approver=${APPROVER} date_utc=${DATE_UTC}"
