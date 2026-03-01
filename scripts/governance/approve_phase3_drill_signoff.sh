#!/usr/bin/env bash
set -euo pipefail

FORM="${FORM:-}"
ROLE="${ROLE:-}"
APPROVER="${APPROVER:-}"
DATE_UTC="${DATE_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
DRY_RUN="${DRY_RUN:-0}"

LOCK_FILE=".git/approve_phase3_drill_signoff.lock"
LOCK_DIR=""

incident_form="docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md"
rollback_form="docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md"

fail() {
  echo "$1" >&2
  exit 1
}

resolve_form_file() {
  case "$FORM" in
    incident) echo "$incident_form" ;;
    rollback) echo "$rollback_form" ;;
    *)
      fail "FORM must be one of: incident|rollback"
      ;;
  esac
}

validate_role_for_form() {
  case "$FORM" in
    incident)
      case "$ROLE" in
        engineering|operations|"product operations") ;;
        *)
          fail "ROLE for incident must be one of: engineering|operations|product operations"
          ;;
      esac
      ;;
    rollback)
      case "$ROLE" in
        engineering|operations|"release manager") ;;
        *)
          fail "ROLE for rollback must be one of: engineering|operations|release manager"
          ;;
      esac
      ;;
  esac
}

validate_inputs() {
  [ -n "$FORM" ] || fail "FORM is required"
  [ -n "$ROLE" ] || fail "ROLE is required"
  [ -n "$APPROVER" ] || fail "APPROVER is required"
  if [[ "$APPROVER" == *"|"* ]]; then
    fail "APPROVER must not contain '|'"
  fi
  if ! [[ "$DATE_UTC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    fail "DATE_UTC must match YYYY-MM-DDTHH:MM:SSZ"
  fi

  validate_role_for_form
}

update_signoff_row() {
  local in_file="$1"
  local out_file="$2"
  awk -v role="$ROLE" -v approver="$APPROVER" -v date_utc="$DATE_UTC" '
    /^## Sign-off$/ { section = "signoff"; print; next }
    /^## / && $0 != "## Sign-off" { section = "other"; print; next }
    {
      if (section == "signoff" && $0 ~ ("^\\| " role " \\|")) {
        print "| " role " | " approver " | " date_utc " | approved |"
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
  rm -f "${tmp_file:-}"
  if [ -n "${LOCK_DIR:-}" ]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}

validate_inputs

form_file="$(resolve_form_file)"
test -f "$form_file" || fail "missing ${form_file}"

acquire_lock

tmp_file="$(mktemp)"
trap cleanup EXIT

update_signoff_row "$form_file" "$tmp_file"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY_RUN] diff for ${form_file}"
  diff -u "$form_file" "$tmp_file" || true
  exit 0
fi

cp "$tmp_file" "$form_file"
echo "updated phase3 drill sign-off form=${FORM} role=${ROLE} approver=${APPROVER} date_utc=${DATE_UTC}"
