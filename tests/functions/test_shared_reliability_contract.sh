#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

auth_file="supabase/functions/_shared/auth.ts"
finalize_file="supabase/functions/_shared/finalize.ts"

test -f "$auth_file" || fail "missing shared auth file"
test -f "$finalize_file" || fail "missing shared finalize file"

rg -q 'let _serviceClient: SupabaseClient \| null = null;' "$auth_file" || fail "missing service client singleton cache"
rg -q 'if \(_serviceClient\) return _serviceClient;' "$auth_file" || fail "missing service client cache reuse branch"
rg -q '_serviceClient = createClient\(' "$auth_file" || fail "missing service client lazy create path"

rg -q 'client\.rpc\("finalize_writeback",' "$finalize_file" || fail "missing finalize_writeback rpc path"
if rg -q '\.from\("snapshot_refresh_events"\)' "$finalize_file"; then
  fail "finalize should not directly write snapshot_refresh_events"
fi
if rg -q '\.from\("operation_logs"\)' "$finalize_file"; then
  fail "finalize should not directly write operation_logs"
fi

echo "shared reliability contract present"
