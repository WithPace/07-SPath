#!/usr/bin/env bash
set -euo pipefail

RECORD_FILE="docs/governance/PHASE-2-RELEASE-RECORD.md"
LOCK_FILE=".git/update_phase2_release_record.lock"
LOCK_DIR=""

COMMIT_SHA="${COMMIT_SHA:-$(git rev-parse --short=12 HEAD)}"
DATE_UTC="${DATE_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
RELEASE_OPERATOR="${RELEASE_OPERATOR:-$(git config user.name 2>/dev/null || echo unknown)}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
DRY_RUN="${DRY_RUN:-0}"

fail() {
  echo "$1" >&2
  exit 1
}

validate_inputs() {
  test -f "$RECORD_FILE" || fail "missing ${RECORD_FILE}"

  if ! [[ "$COMMIT_SHA" =~ ^[0-9a-f]{7,40}$ ]]; then
    fail "COMMIT_SHA must match [0-9a-f]{7,40}"
  fi
  if ! [[ "$DATE_UTC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    fail "DATE_UTC must match YYYY-MM-DDTHH:MM:SSZ"
  fi
  if [[ "$RELEASE_OPERATOR" == *"|"* ]]; then
    fail "RELEASE_OPERATOR must not contain '|'"
  fi
  case "$DRY_RUN" in
    0|1) ;;
    *)
      fail "DRY_RUN must be 0 or 1"
      ;;
  esac
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

update_record() {
  local in_file="$1"
  local out_file="$2"
  awk \
    -v commit_sha="$COMMIT_SHA" \
    -v date_utc="$DATE_UTC" \
    -v release_operator="$RELEASE_OPERATOR" \
    -v project_ref="$SUPABASE_PROJECT_REF" '
    /^## Release Identity$/ { section = "release_identity"; print; next }
    /^## / && $0 != "## Release Identity" { section = "other"; print; next }
    {
      if (section == "release_identity") {
        if ($0 ~ /^\| project_ref \|/ && project_ref != "") {
          print "| project_ref | " project_ref " |"
          next
        }
        if ($0 ~ /^\| commit_sha \|/) {
          print "| commit_sha | " commit_sha " |"
          next
        }
        if ($0 ~ /^\| executed_at_utc \|/) {
          print "| executed_at_utc | " date_utc " |"
          next
        }
        if ($0 ~ /^\| release_operator \|/) {
          print "| release_operator | " release_operator " |"
          next
        }
      }
      print
    }
  ' "$in_file" >"$out_file"
}

validate_output() {
  local file="$1"
  rg -q "^\\| commit_sha \\| ${COMMIT_SHA} \\|$" "$file" || fail "failed to update commit_sha"
  rg -q "^\\| executed_at_utc \\| ${DATE_UTC} \\|$" "$file" || fail "failed to update executed_at_utc"
  rg -q "^\\| release_operator \\| [^|]+ \\|$" "$file" || fail "failed to update release_operator"
  if [ -n "$SUPABASE_PROJECT_REF" ]; then
    rg -q "^\\| project_ref \\| ${SUPABASE_PROJECT_REF} \\|$" "$file" || fail "failed to update project_ref"
  fi
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

update_record "$RECORD_FILE" "$tmp_file"
validate_output "$tmp_file"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY_RUN] diff for ${RECORD_FILE}"
  diff -u "$RECORD_FILE" "$tmp_file" || true
  exit 0
fi

cp "$tmp_file" "$RECORD_FILE"
echo "updated phase2 release record commit_sha=${COMMIT_SHA} date_utc=${DATE_UTC} release_operator=${RELEASE_OPERATOR}"
