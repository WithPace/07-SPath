#!/usr/bin/env bash
set -euo pipefail

test -f .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "^concurrency:" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "cancel-in-progress: true" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase db push" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_chat_casual_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_assessment_training_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_training_record_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_dashboard_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy orchestrator" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy chat-casual" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy assessment" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy training-advice" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy training-record" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase functions deploy dashboard" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "ORCH_MAX_ATTEMPTS" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "ORCH_RETRY_BASE_DELAY_SECONDS" .github/workflows/db-rebuild-and-chain-smoke.yml
echo "db and chain ci gate present"
