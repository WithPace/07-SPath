#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

function_files=(
  "supabase/functions/orchestrator/index.ts"
  "supabase/functions/chat-casual/index.ts"
  "supabase/functions/assessment/index.ts"
  "supabase/functions/training/index.ts"
  "supabase/functions/training-advice/index.ts"
  "supabase/functions/training-record/index.ts"
  "supabase/functions/dashboard/index.ts"
)

for f in "${function_files[@]}"; do
  test -f "$f" || fail "missing function file: $f"

  rg -q 'authenticate\(req\)' "$f" || fail "missing authenticate(req) in $f"
  rg -q 'checkChildAccess\(user\.id, payload\.child_id\)' "$f" || fail "missing checkChildAccess(user.id, payload.child_id) in $f"

  json_count=$(rg -o 'req\.json\(' "$f" | wc -l | tr -d ' ')
  [ "$json_count" = "1" ] || fail "req.json() count mismatch in $f: expected 1, got $json_count"
done

echo "functions auth and body-parse contract present"
