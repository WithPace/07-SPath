#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

deploy_script="scripts/ci/deploy_functions.sh"
release_script="scripts/ci/release_go_live.sh"
final_gate_script="scripts/ci/final_gate.sh"
cli_check_script="scripts/ci/check_supabase_cli_version.sh"
remote_publish_prep_script="scripts/ci/prepare_remote_publish.sh"
release_record_script="scripts/governance/update_phase2_release_record.sh"
rg_shim_script="scripts/bin/rg"

test -f "$deploy_script" || fail "missing deploy script"
test -x "$deploy_script" || fail "deploy script must be executable"
test -f "$release_script" || fail "missing release go-live script"
test -x "$release_script" || fail "release go-live script must be executable"
test -f "$cli_check_script" || fail "missing supabase cli version check script"
test -x "$cli_check_script" || fail "supabase cli version check script must be executable"
test -f "$remote_publish_prep_script" || fail "missing remote publish precheck script"
test -x "$remote_publish_prep_script" || fail "remote publish precheck script must be executable"
test -f "$release_record_script" || fail "missing phase2 release record update script"
test -x "$release_record_script" || fail "phase2 release record update script must be executable"
test -f "$final_gate_script" || fail "missing final gate script"
test -x "$final_gate_script" || fail "final gate script must be executable"
test -f "$rg_shim_script" || fail "missing rg shim script"
test -x "$rg_shim_script" || fail "rg shim script must be executable"

rg -q 'SUPABASE_PROJECT_REF' "$deploy_script" || fail "deploy script missing SUPABASE_PROJECT_REF handling"
rg -q 'bash scripts/ci/check_supabase_cli_version.sh' "$deploy_script" || fail "deploy script missing cli version check step"
rg -q 'supabase functions deploy orchestrator' "$deploy_script" || fail "deploy script missing orchestrator deploy"
rg -q 'supabase functions deploy chat-casual' "$deploy_script" || fail "deploy script missing chat-casual deploy"
rg -q 'supabase functions deploy assessment' "$deploy_script" || fail "deploy script missing assessment deploy"
rg -q 'supabase functions deploy training ' "$deploy_script" || fail "deploy script missing training deploy"
rg -q 'supabase functions deploy training-advice' "$deploy_script" || fail "deploy script missing training-advice deploy"
rg -q 'supabase functions deploy training-record' "$deploy_script" || fail "deploy script missing training-record deploy"
rg -q 'supabase functions deploy dashboard' "$deploy_script" || fail "deploy script missing dashboard deploy"
rg -q 'DRY_RUN' "$deploy_script" || fail "deploy script missing DRY_RUN support"

rg -q 'scripts/ci/deploy_functions.sh' "$release_script" || fail "release script missing deploy step"
rg -q 'bash scripts/ci/check_supabase_cli_version.sh' "$release_script" || fail "release script missing cli version check step"
rg -q 'REQUIRE_FULL_SIGNOFF' "$release_script" || fail "release script missing REQUIRE_FULL_SIGNOFF handling"
rg -q 'scripts/governance/check_phase3_drill_signoff_gate.sh' "$release_script" || fail "release script missing phase3 drill signoff gate step"
rg -q 'REQUIRE_PHASE5_SIGNOFF' "$release_script" || fail "release script missing REQUIRE_PHASE5_SIGNOFF handling"
rg -q 'scripts/governance/check_phase5_signoff_gate.sh' "$release_script" || fail "release script missing phase5 signoff gate step"
rg -q 'bash scripts/ci/final_gate.sh' "$release_script" || fail "release script missing final gate step"
rg -q 'bash tests/governance/test_docs_presence.sh' "$release_script" || fail "release script missing docs gate step"
rg -q 'bash tests/governance/test_e2e_governance.sh' "$release_script" || fail "release script missing e2e governance step"
rg -q 'bash scripts/governance/update_phase2_release_record.sh' "$release_script" || fail "release script missing phase2 release record update step"
rg -q 'DRY_RUN' "$release_script" || fail "release script missing DRY_RUN support"
rg -q 'export PATH=\"\$REPO_ROOT/scripts/bin:\$PATH\"' "$release_script" || fail "release script missing scripts/bin PATH injection"
rg -q 'export PATH=\"\$REPO_ROOT/scripts/bin:\$PATH\"' "$final_gate_script" || fail "final gate script missing scripts/bin PATH injection"

rg -q 'REQUIRE_ORIGIN' "$remote_publish_prep_script" || fail "remote publish precheck missing REQUIRE_ORIGIN handling"
rg -q 'push origin' "$remote_publish_prep_script" || fail "remote publish precheck missing push command plan output"

echo "deploy/release scripts present"
