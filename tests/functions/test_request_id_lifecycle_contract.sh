#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

files=(
  "supabase/functions/chat-casual/index.ts"
  "supabase/functions/assessment/index.ts"
  "supabase/functions/training/index.ts"
  "supabase/functions/training-advice/index.ts"
  "supabase/functions/training-record/index.ts"
  "supabase/functions/dashboard/index.ts"
)

for f in "${files[@]}"; do
  test -f "$f" || fail "missing function file: $f"

  rg -q 'requestId = payload\.request_id \|\| requestId;' "$f" \
    || fail "missing payload request_id inheritance in $f"

  rg -q 'await finalizeWriteback\(\{' "$f" || fail "missing finalizeWriteback call in $f"
  rg -q 'requestId,' "$f" || fail "missing finalizeWriteback requestId passthrough in $f"

  rg -q 'sseEvent\("done"' "$f" || fail "missing done event in $f"
  rg -q 'request_id: requestId' "$f" || fail "missing done event request_id echo in $f"
done

echo "functions request-id lifecycle contract present"
