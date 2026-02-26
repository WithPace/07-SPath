#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

file="supabase/functions/orchestrator/index.ts"
test -f "$file" || fail "missing orchestrator file"

# Downstream forwarding URL and fetch call
rg -q 'const fnUrl = `\$\{Deno\.env\.get\("SUPABASE_URL"\)\}/functions/v1/\$\{route\.functionName\}`;' "$file" \
  || fail "missing downstream function URL contract"
rg -q 'const fnResp = await fetch\(fnUrl, \{' "$file" || fail "missing downstream fetch call"

# Auth header passthrough
rg -q 'Authorization: getAuthHeader\(req\),' "$file" || fail "missing auth header passthrough"

# Forwarding payload canonical fields
rg -q 'child_id: payload\.child_id,' "$file" || fail "missing forwarded child_id"
rg -q 'message: payload\.message,' "$file" || fail "missing forwarded message"
rg -q 'conversation_id: conversationId,' "$file" || fail "missing forwarded conversation_id"
rg -q 'request_id: requestId,' "$file" || fail "missing forwarded request_id"
rg -q 'module: route\.module,' "$file" || fail "missing forwarded module"
rg -q 'orchestrator_latency_ms: Date\.now\(\) - startedAt,' "$file" || fail "missing forwarded orchestrator latency"

# Idempotency short-circuit query constraints
rg -q '\.eq\("request_id", requestId\)' "$file" || fail "missing idempotency request_id filter"
rg -q '\.eq\("action_name", route\.actionName\)' "$file" || fail "missing idempotency action filter"
rg -q '\.eq\("final_status", "completed"\)' "$file" || fail "missing idempotency completed filter"

# SSE response proxy contract
rg -q 'return new Response\(fnResp\.body, \{' "$file" || fail "missing downstream response proxy"
rg -q 'headers: SSE_HEADERS,' "$file" || fail "missing SSE headers on downstream proxy response"

echo "orchestrator forwarding contract present"
