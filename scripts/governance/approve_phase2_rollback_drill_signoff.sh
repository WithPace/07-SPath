#!/usr/bin/env bash
set -euo pipefail

ROLE="${ROLE:-}"
APPROVER="${APPROVER:-}"
DATE_UTC="${DATE_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
DRY_RUN="${DRY_RUN:-0}"

LOG_FILE="docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md"
LOCK_FILE=".git/approve_phase2_rollback_drill_signoff.lock"
LOCK_DIR=""

fail() {
  echo "$1" >&2
  exit 1
}

validate_inputs() {
  case "$ROLE" in
    engineering|operations) ;;
    *)
      fail "ROLE must be one of: engineering|operations"
      ;;
  esac

  [ -n "$APPROVER" ] || fail "APPROVER is required"
  if [[ "$APPROVER" == *"|"* ]]; then
    fail "APPROVER must not contain '|'"
  fi
  if ! [[ "$DATE_UTC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    fail "DATE_UTC must match YYYY-MM-DDTHH:MM:SSZ"
  fi

  test -f "$LOG_FILE" || fail "missing ${LOG_FILE}"
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

update_row() {
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

cleanup() {
  rm -f "${tmp_file:-}"
  if [ -n "${LOCK_DIR:-}" ]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}

validate_inputs
acquire_lock

tmp_file="$(mktemp)"
trap cleanup EXIT

update_row "$LOG_FILE" "$tmp_file"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY_RUN] diff for ${LOG_FILE}"
  diff -u "$LOG_FILE" "$tmp_file" || true
  exit 0
fi

cp "$tmp_file" "$LOG_FILE"
echo "updated phase2 rollback drill sign-off role=${ROLE} approver=${APPROVER} date_utc=${DATE_UTC}"
