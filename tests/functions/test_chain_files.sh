#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/orchestrator/index.ts
test -f supabase/functions/chat-casual/index.ts
test -f supabase/functions/assessment/index.ts
test -f supabase/functions/training/index.ts
test -f supabase/functions/training-advice/index.ts
test -f supabase/functions/training-record/index.ts
test -f supabase/functions/dashboard/index.ts
grep -q "request_id" supabase/functions/orchestrator/index.ts
grep -q "training_advice" supabase/functions/orchestrator/index.ts
grep -q "assessment" supabase/functions/orchestrator/index.ts
grep -q "training_generate" supabase/functions/orchestrator/index.ts
grep -q "training_record" supabase/functions/orchestrator/index.ts
grep -q "dashboard" supabase/functions/orchestrator/index.ts
grep -q "finalizeWriteback" supabase/functions/chat-casual/index.ts
grep -q "children_memory" supabase/functions/chat-casual/index.ts
grep -q "finalizeWriteback" supabase/functions/assessment/index.ts
grep -q "children_profiles" supabase/functions/assessment/index.ts
grep -q "affectedTables: .*chat_messages" supabase/functions/assessment/index.ts
grep -q "finalizeWriteback" supabase/functions/training/index.ts
grep -q "children_memory" supabase/functions/training/index.ts
grep -q "affectedTables: .*chat_messages" supabase/functions/training/index.ts
grep -q "finalizeWriteback" supabase/functions/training-advice/index.ts
grep -q "children_memory" supabase/functions/training-advice/index.ts
grep -q "affectedTables: .*chat_messages" supabase/functions/training-advice/index.ts
grep -q "finalizeWriteback" supabase/functions/training-record/index.ts
grep -q "children_profiles" supabase/functions/training-record/index.ts
grep -q "affectedTables: .*chat_messages" supabase/functions/training-record/index.ts
grep -q "finalizeWriteback" supabase/functions/dashboard/index.ts
grep -q "affectedTables: .*chat_messages" supabase/functions/dashboard/index.ts
echo "chain files and key hooks present"
