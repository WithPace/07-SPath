#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

files=(
  "supabase/functions/orchestrator/index.ts"
  "supabase/functions/chat-casual/index.ts"
  "supabase/functions/assessment/index.ts"
  "supabase/functions/training/index.ts"
  "supabase/functions/training-advice/index.ts"
  "supabase/functions/training-record/index.ts"
  "supabase/functions/dashboard/index.ts"
)

for f in "${files[@]}"; do
  test -f "$f" || fail "missing function file: $f"

  rg -q 'sseError\("BAD_REQUEST"' "$f" || fail "missing BAD_REQUEST sse error in $f"
  rg -q 'status: 400' "$f" || fail "missing HTTP 400 mapping in $f"

  rg -q 'sseError\("AUTH_FORBIDDEN"' "$f" || fail "missing AUTH_FORBIDDEN sse error in $f"
  rg -q 'status: 403' "$f" || fail "missing HTTP 403 mapping in $f"

  rg -q 'sseError\("INTERNAL_ERROR"' "$f" || fail "missing INTERNAL_ERROR sse error in $f"
  rg -q 'status: 500' "$f" || fail "missing HTTP 500 mapping in $f"

  rg -q 'headers: SSE_HEADERS' "$f" || fail "missing SSE headers contract in $f"
done

echo "functions error response contract present"
