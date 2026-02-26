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

  rg -q 'if \(req\.method === "OPTIONS"\)' "$f" \
    || fail "missing OPTIONS guard in $f"

  rg -q 'return new Response\(null, \{ headers: SSE_HEADERS \}\);' "$f" \
    || fail "missing OPTIONS preflight response in $f"
done

echo "functions options preflight contract present"
