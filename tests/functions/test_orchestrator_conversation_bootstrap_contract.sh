#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

file="supabase/functions/orchestrator/index.ts"
test -f "$file" || fail "missing orchestrator file"

rg -q 'if \(!conversationId\) \{' "$file" || fail "missing conversation bootstrap branch"
rg -q '\.from\("conversations"\)' "$file" || fail "missing conversations insert target"
rg -q 'title: "新对话",' "$file" || fail "missing conversation title default"
rg -q 'last_message_at: new Date\(\)\.toISOString\(\),' "$file" || fail "missing conversation last_message_at field"
rg -q 'message_count: 0,' "$file" || fail "missing conversation message_count default"
rg -q 'is_deleted: false,' "$file" || fail "missing conversation is_deleted default"
rg -q 'throw new Error\(`INTERNAL_ERROR: create conversation failed:' "$file" || fail "missing create conversation failure throw"

rg -q '\.from\("chat_messages"\)\.insert\(\{' "$file" || fail "missing user message insert call"
rg -q 'conversation_id: conversationId,' "$file" || fail "missing user message conversation_id field"
rg -q 'child_id: payload\.child_id,' "$file" || fail "missing user message child_id field"
rg -q 'user_id: user\.id,' "$file" || fail "missing user message user_id field"
rg -q 'role: "user",' "$file" || fail "missing user message role field"
rg -q 'content: payload\.message,' "$file" || fail "missing user message content field"
rg -q 'edge_function: "orchestrator",' "$file" || fail "missing user message edge_function field"
rg -q 'throw new Error\(`INTERNAL_ERROR: write user message failed:' "$file" || fail "missing user message failure throw"

echo "orchestrator conversation bootstrap contract present"
