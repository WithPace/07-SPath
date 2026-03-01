#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/ci/check_supabase_cli_version.sh"
db_preflight="scripts/db/preflight.sh"

test -f "$script" || fail "missing supabase cli check script"
test -x "$script" || fail "supabase cli check script must be executable"
rg -q 'SUPABASE_CLI_EXPECTED_VERSION' "$script" || fail "cli check script must define expected version"
rg -q 'ENFORCE_SUPABASE_CLI_VERSION' "$script" || fail "cli check script must support enforce toggle"
rg -q 'supabase --version' "$script" || fail "cli check script must read current cli version"
rg -q 'must update supabase cli' "$script" || fail "cli check script must print update guidance"

test -f "$db_preflight" || fail "missing db preflight script"
rg -q 'bash scripts/ci/check_supabase_cli_version.sh' "$db_preflight" || fail "db preflight must run cli check script"

echo "supabase cli check script present"
