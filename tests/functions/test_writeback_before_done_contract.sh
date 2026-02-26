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

  rg -q 'await finalizeWriteback\(\{' "$f" \
    || fail "missing finalizeWriteback call in $f"
  rg -q 'sseEvent\("done", ' "$f" \
    || fail "missing done event in $f"

  writeback_ln="$(rg -n 'await finalizeWriteback\(\{' "$f" | head -n 1 | cut -d: -f1)"
  done_ln="$(rg -n 'sseEvent\(\"done\", ' "$f" | head -n 1 | cut -d: -f1)"

  (( writeback_ln < done_ln )) || fail "invalid ordering (writeback before done) in $f"
done

echo "functions writeback-before-done contract present"
