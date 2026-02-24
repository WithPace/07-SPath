#!/usr/bin/env bash
set -euo pipefail

test -f .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase db push" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_chat_casual_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy orchestrator" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy chat-casual" .github/workflows/db-rebuild-and-chain-smoke.yml
echo "db and chain ci gate present"
