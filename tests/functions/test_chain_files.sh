#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/orchestrator/index.ts
test -f supabase/functions/chat-casual/index.ts
grep -q "request_id" supabase/functions/orchestrator/index.ts
grep -q "finalizeWriteback" supabase/functions/chat-casual/index.ts
echo "chain files and key hooks present"
