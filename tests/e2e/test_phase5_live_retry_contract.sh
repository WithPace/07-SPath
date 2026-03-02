#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="tests/e2e/test_phase5_doctor_teacher_org_journeys_live.sh"
test -f "$script" || fail "missing phase5 multi-role live script"

rg -q 'WORKER_LIMIT' "$script" || fail "phase5 multi-role live script missing WORKER_LIMIT retry handling"
rg -q 'max_attempts=' "$script" || fail "phase5 multi-role live script missing max_attempts control"
rg -q 'for \(\(attempt = 1; attempt <= max_attempts; attempt \+= 1\)\)' "$script" \
  || fail "phase5 multi-role live script missing retry loop"
rg -q 'sleep_seconds=' "$script" || fail "phase5 multi-role live script missing exponential backoff"

echo "phase5 live retry contract present"
