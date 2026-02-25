#!/usr/bin/env bash
set -euo pipefail

file="supabase/functions/orchestrator/index.ts"

# canonical route tuples
grep -q 'functionName: "chat-casual"' "$file"
grep -q 'actionName: "chat_casual_reply"' "$file"
grep -q 'module: "chat_casual"' "$file"

grep -q 'functionName: "assessment"' "$file"
grep -q 'actionName: "assessment_generate"' "$file"
grep -q 'module: "assessment"' "$file"

grep -q 'functionName: "training"' "$file"
grep -q 'actionName: "training_generate"' "$file"
grep -q 'module: "training"' "$file"

grep -q 'functionName: "training-advice"' "$file"
grep -q 'actionName: "training_advice_generate"' "$file"
grep -q 'module: "training_advice"' "$file"

grep -q 'functionName: "training-record"' "$file"
grep -q 'actionName: "training_record_create"' "$file"
grep -q 'module: "training_record"' "$file"

grep -q 'functionName: "dashboard"' "$file"
grep -q 'actionName: "dashboard_generate"' "$file"
grep -q 'module: "dashboard"' "$file"

# alias coverage
grep -q 'normalized === "chat_casual" || normalized === "chat"' "$file"
grep -q 'normalized === "training" || normalized === "train" || normalized === "training_plan"' "$file"
grep -q 'normalized === "training_advice" || normalized === "trainingadvice"' "$file"
grep -q 'normalized === "training_record" || normalized === "trainingrecord"' "$file"
grep -q 'normalized === "dashboard" || normalized === "analysis"' "$file"

echo "orchestrator route contract checks pass"
