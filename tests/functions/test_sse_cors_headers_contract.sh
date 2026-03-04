#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

file="supabase/functions/_shared/sse.ts"
test -f "$file" || fail "missing shared sse module: $file"

rg -q '"Access-Control-Allow-Origin"' "$file" \
  || fail "missing Access-Control-Allow-Origin in SSE_HEADERS"

rg -q '"Access-Control-Allow-Headers"' "$file" \
  || fail "missing Access-Control-Allow-Headers in SSE_HEADERS"

rg -q 'authorization' "$file" \
  || fail "missing authorization in Access-Control-Allow-Headers"

rg -q 'content-type' "$file" \
  || fail "missing content-type in Access-Control-Allow-Headers"

rg -q '"Access-Control-Allow-Methods"' "$file" \
  || fail "missing Access-Control-Allow-Methods in SSE_HEADERS"

rg -q 'POST, OPTIONS' "$file" \
  || fail "missing POST, OPTIONS in Access-Control-Allow-Methods"

echo "sse cors headers contract present"
