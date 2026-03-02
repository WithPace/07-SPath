#!/usr/bin/env bash
set -euo pipefail

ROLE="${ROLE:-}"
APPROVER="${APPROVER:-}"
DATE_UTC="${DATE_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
DRY_RUN="${DRY_RUN:-0}"

CHECKLIST_FILE="docs/governance/PHASE-5-DELIVERY-CHECKLIST.md"
RECORD_FILE="docs/governance/PHASE-5-RELEASE-RECORD.md"
LOCK_FILE=".git/approve_phase5_signoff.lock"
LOCK_DIR=""

fail() {
  echo "$1" >&2
  exit 1
}

validate_role() {
  case "$ROLE" in
    "backend engineering"|"frontend engineering"|"admin web engineering"|product|operations|security) ;;
    *)
      fail "ROLE must be one of: backend engineering|frontend engineering|admin web engineering|product|operations|security"
      ;;
  esac
}

validate_inputs() {
  validate_role
  [ -n "$APPROVER" ] || fail "APPROVER is required"
  if [[ "$APPROVER" == *"|"* ]]; then
    fail "APPROVER must not contain '|'"
  fi
  if ! [[ "$DATE_UTC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    fail "DATE_UTC must match YYYY-MM-DDTHH:MM:SSZ"
  fi
  test -f "$CHECKLIST_FILE" || fail "missing $CHECKLIST_FILE"
  test -f "$RECORD_FILE" || fail "missing $RECORD_FILE"
}

update_checklist_row() {
  local in_file="$1"
  local out_file="$2"
  awk -v role="$ROLE" -v approver="$APPROVER" -v date_utc="$DATE_UTC" '
    /^## Cross-Repo Sign-off$/ { section = "signoff"; print; next }
    /^## / && $0 != "## Cross-Repo Sign-off" { section = "other"; print; next }
    {
      if (section == "signoff" && $0 ~ ("^\\| " role " \\|")) {
        print "| " role " | " approver " | " date_utc " | approved |"
        next
      }
      print
    }
  ' "$in_file" >"$out_file"
}

all_signoff_roles_approved() {
  local file="$1"
  local roles=(
    "backend engineering"
    "frontend engineering"
    "admin web engineering"
    "product"
    "operations"
    "security"
  )
  local role status
  for role in "${roles[@]}"; do
    status="$(awk -F'|' -v role="$role" '/^\| / {
      raw = $0
      gsub(/^[ \t]+|[ \t]+$/, "", raw)
      if (raw ~ ("^\\| " role " \\|")) {
        val = $5
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        print val
        exit
      }
    }' "$file")"
    [ "$status" = "approved" ] || return 1
  done
  return 0
}

update_record_integrated_row() {
  local in_file="$1"
  local out_file="$2"
  local status_value="$3"
  local note_value="$4"
  awk -v status_value="$status_value" -v note_value="$note_value" '
    {
      if ($0 ~ /^\| integrated sign-off complete \|/) {
        print "| integrated sign-off complete | " status_value " | " note_value " |"
        next
      }
      print
    }
  ' "$in_file" >"$out_file"
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    flock -x 9
    return
  fi

  LOCK_DIR="${LOCK_FILE}.d"
  local attempts=0
  local max_attempts=300
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge "$max_attempts" ]; then
      fail "unable to acquire lock after ${max_attempts}s: ${LOCK_DIR}"
    fi
    sleep 1
  done
}

cleanup() {
  rm -f "${tmp_checklist:-}" "${tmp_record:-}"
  if [ -n "${LOCK_DIR:-}" ]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}

validate_inputs
acquire_lock

tmp_checklist="$(mktemp)"
tmp_record="$(mktemp)"
trap cleanup EXIT

update_checklist_row "$CHECKLIST_FILE" "$tmp_checklist"

if all_signoff_roles_approved "$tmp_checklist"; then
  integrated_status="done"
  integrated_note="all required sign-off rows approved"
else
  integrated_status="pending"
  integrated_note="waiting approval matrix closure"
fi

update_record_integrated_row "$RECORD_FILE" "$tmp_record" "$integrated_status" "$integrated_note"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY_RUN] diff for ${CHECKLIST_FILE}"
  diff -u "$CHECKLIST_FILE" "$tmp_checklist" || true
  echo "[DRY_RUN] diff for ${RECORD_FILE}"
  diff -u "$RECORD_FILE" "$tmp_record" || true
  exit 0
fi

cp "$tmp_checklist" "$CHECKLIST_FILE"
cp "$tmp_record" "$RECORD_FILE"

echo "updated phase5 sign-off role=${ROLE} approver=${APPROVER} date_utc=${DATE_UTC} integrated_status=${integrated_status}"
