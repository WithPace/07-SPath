#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

require_done_baseline() {
  local f="$1"
  test -f "$f" || fail "missing function file: $f"
  rg -q 'sseEvent\("done", ' "$f" || fail "missing done event in $f"
  rg -q 'request_id: requestId' "$f" || fail "missing request_id in done payload ($f)"
  rg -q 'model_used: model\.modelUsed' "$f" || fail "missing model_used in done payload ($f)"
}

chat="supabase/functions/chat-casual/index.ts"
assessment="supabase/functions/assessment/index.ts"
training="supabase/functions/training/index.ts"
training_advice="supabase/functions/training-advice/index.ts"
training_record="supabase/functions/training-record/index.ts"
dashboard="supabase/functions/dashboard/index.ts"

require_done_baseline "$chat"
require_done_baseline "$assessment"
require_done_baseline "$training"
require_done_baseline "$training_advice"
require_done_baseline "$training_record"
require_done_baseline "$dashboard"

rg -q 'assessment_id: assessmentInsert\.data\.id' "$assessment" \
  || fail "missing assessment_id done field contract"

rg -q 'training_plan_id: planInsert\.data\.id' "$training" \
  || fail "missing training plan done field in training"
rg -q 'training_plan_id: planInsert\.data\.id' "$training_advice" \
  || fail "missing training plan done field in training-advice"

rg -q 'training_session_id: sessionInsert\.data\.id' "$training_record" \
  || fail "missing training session done field contract"

rg -q 'role: "parent"' "$dashboard" || fail "missing dashboard role field contract"
rg -q 'card_count: cards\.length' "$dashboard" || fail "missing dashboard card_count field contract"
rg -q 'sseEvent\("delta", \{ text: model\.text, cards \}\)' "$dashboard" \
  || fail "missing dashboard delta cards payload contract"

echo "phase2 business output contract present"
