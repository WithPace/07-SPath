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

  rg -q 'sseEvent\("stream_start", \{ request_id: requestId \}\)' "$f" \
    || fail "missing stream_start event contract in $f"
  rg -q 'sseEvent\("delta", \{ text: model\.text' "$f" \
    || fail "missing delta event contract in $f"
  rg -q 'sseEvent\("done", \{' "$f" \
    || fail "missing done event contract in $f"

  start_ln="$(rg -n 'sseEvent\(\"stream_start\", \{ request_id: requestId \}\)' "$f" | head -n 1 | cut -d: -f1)"
  delta_ln="$(rg -n 'sseEvent\(\"delta\", \{ text: model\.text' "$f" | head -n 1 | cut -d: -f1)"
  done_ln="$(rg -n 'sseEvent\(\"done\", \{' "$f" | head -n 1 | cut -d: -f1)"

  (( start_ln < delta_ln )) || fail "invalid SSE order (stream_start before delta) in $f"
  (( delta_ln < done_ln )) || fail "invalid SSE order (delta before done) in $f"
done

echo "functions sse framing contract present"
