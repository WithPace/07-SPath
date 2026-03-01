#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/db/preflight.sh"
test -f "$script" || fail "missing db preflight script"
test -x "$script" || fail "db preflight script must be executable"

rg -q 'check_supabase_cli_version.sh' "$script" || fail "preflight must run supabase cli version check"
rg -q 'for key in .*SUPABASE_URL.*SUPABASE_SERVICE_ROLE_KEY.*SUPABASE_DB_PASSWORD.*DOUBAO_API_KEY.*KIMI_API_KEY.*; do' "$script" \
  || fail "preflight key loop must include SUPABASE_DB_PASSWORD and all required keys"

echo "db preflight contract present"
