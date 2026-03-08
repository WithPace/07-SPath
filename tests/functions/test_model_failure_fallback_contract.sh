#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

assert_model_fallback_contract() {
  local file="$1"
  local rule="$2"
  test -f "$file" || fail "missing function file: $file"
  rg -q "let model = \\{ text: \"\", modelUsed: \"${rule}\" \\};" "$file" \
    || fail "missing fallback model bootstrap (${file})"
  rg -q 'model = await callModelLive\(\[' "$file" \
    || fail "missing live model call assignment (${file})"
  rg -q 'catch \{' "$file" || fail "missing fallback catch branch (${file})"
}

assert_model_fallback_contract "supabase/functions/chat-casual/index.ts" "chat_fallback_rule"
assert_model_fallback_contract "supabase/functions/dashboard/index.ts" "dashboard_fallback_rule"
assert_model_fallback_contract "supabase/functions/assessment/index.ts" "assessment_fallback_rule"
assert_model_fallback_contract "supabase/functions/training/index.ts" "training_fallback_rule"
assert_model_fallback_contract "supabase/functions/training-advice/index.ts" "training_advice_fallback_rule"
assert_model_fallback_contract "supabase/functions/training-record/index.ts" "training_record_fallback_rule"

echo "model failure fallback contract present"
