#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

file="supabase/functions/_shared/model-router.ts"
test -f "$file" || fail "missing model-router file"

# Provider pick contract
rg -q 'const preferred = \(Deno\.env\.get\("DEFAULT_LLM"\) \?\? "doubao"\)\.toLowerCase\(\);' "$file" \
  || fail "missing DEFAULT_LLM provider preference contract"
rg -q 'if \(preferred\.includes\("kimi"\)\) return "kimi";' "$file" || fail "missing kimi provider match contract"
rg -q 'return "doubao";' "$file" || fail "missing doubao default provider contract"

# Non-streaming chat-completions contract
stream_count=$(rg -o 'stream: false' "$file" | wc -l | tr -d ' ')
[ "$stream_count" = "2" ] || fail "stream:false contract mismatch, expected 2 occurrences, got $stream_count"

# Dual fallback branch contract
rg -q 'if \(provider === "doubao"\) \{' "$file" || fail "missing doubao primary branch"
rg -q 'const text = await callDoubao\(messages, options\);' "$file" || fail "missing doubao primary invocation"
rg -q 'const text = await callKimi\(messages, options\);' "$file" || fail "missing kimi invocation contract"
rg -q 'catch \{' "$file" || fail "missing fallback catch branch"

# Doubao model resolution guard
rg -q 'if \(!model\) \{' "$file" || fail "missing doubao model guard branch"
rg -q 'throw new Error\("missing env: DOUBAO_ENDPOINT_ID or DOUBAO_MODEL"\);' "$file" \
  || fail "missing doubao model guard error contract"

echo "model-router resilience contract present"
