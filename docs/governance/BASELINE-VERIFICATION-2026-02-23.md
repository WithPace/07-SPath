# Governance Baseline Verification (2026-02-23)

## Scope

- Contract source validation
- Artifact generation
- Required clauses verification
- Runtime target sync
- CI workflow presence
- Rebuild execution-chain baseline linkage (full 7-module chain)

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
17. `bash scripts/ci/final_gate.sh` -> PASS (`governance + db + functions + e2e + ci` full sweep)
18. `bash tests/ci/test_workflow_presence.sh` -> PASS
19. `bash tests/e2e/test_orchestrator_training_live.sh` -> PASS
20. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS
21. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS
22. `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
23. `bash tests/e2e/test_orchestrator_training_live.sh` -> PASS (`training_request_id=b9cd1f2a-eba6-4140-8446-193b559f0472`)
24. `bash scripts/ci/final_gate.sh` -> PASS
25. `supabase functions deploy dashboard --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
26. `bash tests/e2e/test_orchestrator_dashboard_live.sh` -> PASS (`dashboard_request_id=391a0df3-bc6a-4a4d-a301-e08f909df192`)
27. `bash scripts/ci/final_gate.sh` -> PASS
28. `supabase functions deploy assessment --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
29. `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
30. `supabase functions deploy training-advice --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
31. `supabase functions deploy training-record --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
32. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS (`assessment_request_id=63e5aea2-755a-4515-9b74-c313d00c477e`, `training_request_id=e3f27ff6-2cd3-4e44-b50a-171314988ed2`)
33. `bash tests/e2e/test_orchestrator_training_live.sh` -> PASS (`training_request_id=5090a0cc-65b3-427a-b795-b203a47b3484`)
34. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS (`training_record_request_id=fc5fe82f-7721-44c0-baf8-2605a7d20147`)
35. `bash scripts/ci/final_gate.sh` -> PASS
36. `bash tests/functions/test_affected_tables_contract.sh` -> PASS
37. `bash scripts/ci/final_gate.sh` -> PASS
38. `bash tests/functions/test_writeback_metadata_contract.sh` -> PASS
39. `bash scripts/ci/final_gate.sh` -> PASS
40. `bash tests/functions/test_orchestrator_route_contract.sh` -> PASS
41. `bash scripts/ci/final_gate.sh` -> PASS
42. `bash tests/e2e/test_orchestrator_idempotency_live.sh` -> PASS (`request_id=c890ad51-e749-4e7e-a25e-e40feca78484`)
43. `bash scripts/ci/final_gate.sh` -> PASS
44. `bash tests/e2e/test_live_smoke_cleanup_contract.sh` -> PASS
45. `bash scripts/ci/final_gate.sh` -> PASS
46. `bash tests/e2e/test_live_smoke_retry_contract.sh` -> PASS
47. `bash scripts/ci/final_gate.sh` -> PASS
48. `bash tests/e2e/test_live_smoke_retry_limits_contract.sh` -> PASS
49. `bash scripts/ci/final_gate.sh` -> PASS
50. Latest verification timestamp (UTC): `2026-02-25T01:51:12Z`

## Outputs

- `AGENTS.md` generated and synced
- `CLAUDE.md` generated and synced
- `.cursor/rules/starpath-contract.mdc` generated and synced
- `governance/agent-contract/contract.lock.json` generated
- Live chain writes validated in `chat_messages`, `operation_logs`, `snapshot_refresh_events`
- Chat-casual memory writeback validated in `children_memory.last_interaction_summary`
- Assessment/training domain writes validated in `assessments`, `training_plans`, `children_profiles`, `children_memory`
- Training module writeback validated with `operation_logs(action_name=training_generate)` and `affected_tables` including `children_memory`, `chat_messages`
- Training-advice/assessment writeback metadata validated with `affected_tables` including `chat_messages`
- Training-record domain writes validated in `training_sessions`, `children_profiles`, with metadata including `chat_messages`
- Dashboard writes validated in `chat_messages.cards_json` with `operation_logs(action_name=dashboard_generate)` and `affected_tables` including `chat_messages`
- Static affected-tables contract gate validates action/table metadata for all 6 execution modules
- Static writeback-metadata contract gate validates action/event/snapshot metadata for all 6 execution modules
- Static orchestrator-route contract gate validates alias/function/action/module route tuples
- Static live-smoke cleanup contract gate validates cleanup hooks in all live orchestrator scripts
- Static live-smoke retry contract gate validates helper retry semantics and all live-script retry defaults
- Static live-smoke retry-limits contract gate validates bounded retry env parameters for stable live-smoke behavior
- Live idempotency gate validates duplicate request short-circuit and single completion operation log behavior
- Contract generation confirms `Module Contracts (7)` for current execution-chain modules

## Current Status

- Tracked baseline gaps (`GAP-0001` ~ `GAP-0003`) are currently marked `done` in `docs/governance/GAP-REGISTER.md`.
- Future modules must be added to `governance/agent-contract/source/contract.yaml` required list before release.
- CI gate for DB rebuild + execution-chain smoke is active in `.github/workflows/db-rebuild-and-chain-smoke.yml`.
