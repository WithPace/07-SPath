#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

file="supabase/functions/_shared/model-router.ts"
test -f "$file" || fail "missing model-router file"

rg -q 'const temperature = options\.temperature \?\? 1;' "$file" \
  || fail "missing kimi temperature option fallback contract"
rg -q 'temperature,' "$file" || fail "missing kimi payload temperature field contract"
rg -q 'temperature: options\.temperature \?\? 0\.4,' "$file" \
  || fail "missing doubao temperature option fallback contract"

echo "model-router temperature contract present"
