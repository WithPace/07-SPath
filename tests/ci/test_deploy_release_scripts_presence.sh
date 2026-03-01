#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

deploy_script="scripts/ci/deploy_functions.sh"
release_script="scripts/ci/release_go_live.sh"

test -f "$deploy_script" || fail "missing deploy script"
test -x "$deploy_script" || fail "deploy script must be executable"
test -f "$release_script" || fail "missing release go-live script"
test -x "$release_script" || fail "release go-live script must be executable"

rg -q 'SUPABASE_PROJECT_REF' "$deploy_script" || fail "deploy script missing SUPABASE_PROJECT_REF handling"
rg -q 'supabase functions deploy orchestrator' "$deploy_script" || fail "deploy script missing orchestrator deploy"
rg -q 'supabase functions deploy chat-casual' "$deploy_script" || fail "deploy script missing chat-casual deploy"
rg -q 'supabase functions deploy assessment' "$deploy_script" || fail "deploy script missing assessment deploy"
rg -q 'supabase functions deploy training ' "$deploy_script" || fail "deploy script missing training deploy"
rg -q 'supabase functions deploy training-advice' "$deploy_script" || fail "deploy script missing training-advice deploy"
rg -q 'supabase functions deploy training-record' "$deploy_script" || fail "deploy script missing training-record deploy"
rg -q 'supabase functions deploy dashboard' "$deploy_script" || fail "deploy script missing dashboard deploy"
rg -q 'DRY_RUN' "$deploy_script" || fail "deploy script missing DRY_RUN support"

rg -q 'scripts/ci/deploy_functions.sh' "$release_script" || fail "release script missing deploy step"
rg -q 'bash scripts/ci/final_gate.sh' "$release_script" || fail "release script missing final gate step"
rg -q 'bash tests/governance/test_docs_presence.sh' "$release_script" || fail "release script missing docs gate step"
rg -q 'bash tests/governance/test_e2e_governance.sh' "$release_script" || fail "release script missing e2e governance step"
rg -q 'DRY_RUN' "$release_script" || fail "release script missing DRY_RUN support"

echo "deploy/release scripts present"
