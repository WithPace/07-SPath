#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/orchestrator/index.ts
test -f supabase/functions/chat-casual/index.ts
test -f supabase/functions/assessment/index.ts
test -f supabase/functions/training-advice/index.ts
grep -q "request_id" supabase/functions/orchestrator/index.ts
grep -q "training_advice" supabase/functions/orchestrator/index.ts
grep -q "assessment" supabase/functions/orchestrator/index.ts
grep -q "finalizeWriteback" supabase/functions/chat-casual/index.ts
grep -q "finalizeWriteback" supabase/functions/assessment/index.ts
grep -q "finalizeWriteback" supabase/functions/training-advice/index.ts
echo "chain files and key hooks present"
