# Governance Baseline Verification (2026-02-23)

## Scope

- Contract source validation
- Artifact generation
- Required clauses verification
- Runtime target sync
- CI workflow presence
- Rebuild execution-chain baseline linkage (including dashboard chain)

## Command Evidence

1. `bash tests/governance/test_contract_seed.sh` -> PASS
2. `bash tests/governance/test_schema_validation.sh` -> PASS
3. `bash tests/governance/test_build_generation.sh` -> PASS
4. `bash tests/governance/test_verify_contract.sh` -> PASS
5. `bash tests/governance/test_sync_targets.sh` -> PASS
6. `bash tests/governance/test_docs_presence.sh` -> PASS
7. `bash tests/governance/test_ci_workflow.sh` -> PASS
8. `bash tests/governance/test_e2e_governance.sh` -> PASS
9. `bash tests/governance/test_module_contracts_seed.sh` -> PASS
10. `bash tests/governance/test_build_includes_modules.sh` -> PASS
11. `bash tests/functions/test_shared_modules.sh` -> PASS
12. `bash tests/functions/test_chain_files.sh` -> PASS
13. `bash tests/e2e/test_orchestrator_chat_casual_live.sh` -> PASS
14. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS
15. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS
16. `bash tests/e2e/test_orchestrator_dashboard_live.sh` -> PASS

## Outputs

- `AGENTS.md` generated and synced
- `CLAUDE.md` generated and synced
- `.cursor/rules/starpath-contract.mdc` generated and synced
- `governance/agent-contract/contract.lock.json` generated
- Live chain writes validated in `chat_messages`, `operation_logs`, `snapshot_refresh_events`
- Assessment/training domain writes validated in `assessments`, `training_plans`
- Training-record domain writes validated in `training_sessions`
- Dashboard writes validated in `chat_messages.cards_json` with `operation_logs(action_name=dashboard_generate)`

## Open Gaps

- Three module contracts are defined (`orchestrator`, `assessment`, `training`); dashboard runtime chain is live, but dashboard-specific module contract is still pending and tracked in `docs/governance/GAP-REGISTER.md`.
- CI gate for DB rebuild + execution-chain smoke is active in `.github/workflows/db-rebuild-and-chain-smoke.yml`.
