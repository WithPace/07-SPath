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
50. `bash tests/e2e/test_live_smoke_retry_observability_contract.sh` -> PASS
51. `bash scripts/ci/final_gate.sh` -> PASS
52. `bash tests/e2e/test_live_smoke_retry_reason_contract.sh` -> PASS
53. `bash scripts/ci/final_gate.sh` -> PASS
54. `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh` -> PASS
55. `bash scripts/ci/final_gate.sh` -> PASS
56. `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh` -> PASS
57. `bash scripts/ci/final_gate.sh` -> PASS
58. `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh` -> PASS
59. `bash scripts/ci/final_gate.sh` -> PASS
60. `bash tests/e2e/test_live_smoke_retry_cards_contract.sh` -> PASS
61. `bash scripts/ci/final_gate.sh` -> PASS
62. `bash tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh` -> PASS
63. `bash scripts/ci/final_gate.sh` -> PASS
64. `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh` -> PASS
65. `bash scripts/ci/final_gate.sh` -> PASS
66. `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh` -> PASS
67. `bash scripts/ci/final_gate.sh` -> PASS
68. `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh` -> PASS
69. `bash scripts/ci/final_gate.sh` -> PASS
70. `bash tests/e2e/test_live_smoke_retry_transport_observability_contract.sh` -> PASS
71. `bash scripts/ci/final_gate.sh` -> PASS
72. `bash tests/governance/test_docs_presence.sh` -> PASS
73. `bash tests/governance/test_e2e_governance.sh` -> PASS
74. Latest verification timestamp (UTC): `2026-02-26T07:01:10Z`
75. `bash tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh` -> PASS
76. `bash scripts/ci/final_gate.sh` -> PASS
77. `bash tests/governance/test_docs_presence.sh` -> PASS
78. `bash tests/governance/test_e2e_governance.sh` -> PASS
79. Final-gate retry-transport-exit-code smoke sample (`assessment_request_id=b655bed7-9add-4a43-8123-c4b477adab2d`, `training_request_id=b769aef9-fde3-4626-ac84-cf5e3fc06188`, `chat_request_id=4a073791-fa32-4305-8818-11345b110301`)
80. Latest verification timestamp (UTC): `2026-02-26T07:31:20Z`
81. `bash tests/functions/test_auth_and_body_parse_contract.sh` -> PASS
82. `bash scripts/ci/final_gate.sh` -> PASS
83. `bash tests/governance/test_docs_presence.sh` -> PASS
84. `bash tests/governance/test_e2e_governance.sh` -> PASS
85. Final-gate auth-body-parse-contract smoke sample (`assessment_request_id=0d23cbaa-f1ea-446d-9a2b-96c6468c49f3`, `training_request_id=7baeb2df-fa1e-493a-9206-1047970b7aa3`, `chat_request_id=28ba0b53-a1d1-4549-b912-594f54bcd60e`)
86. Latest verification timestamp (UTC): `2026-02-26T07:54:28Z`
87. `bash tests/functions/test_shared_reliability_contract.sh` -> PASS
88. `bash scripts/ci/final_gate.sh` -> PASS
89. `bash tests/governance/test_docs_presence.sh` -> PASS
90. `bash tests/governance/test_e2e_governance.sh` -> PASS
91. Final-gate shared-reliability-contract smoke sample (`assessment_request_id=1c44fb6f-8d9a-4260-9f3b-059eea3cfd53`, `training_request_id=8aef9f4c-51a9-4fdf-b867-939eb50f75cd`, `chat_request_id=63621fca-5954-47b1-b5c6-d1dd6686d48c`)
92. Latest verification timestamp (UTC): `2026-02-26T09:37:00Z`
93. `bash tests/functions/test_orchestrator_forwarding_contract.sh` -> PASS
94. `bash scripts/ci/final_gate.sh` -> PASS
95. `bash tests/governance/test_docs_presence.sh` -> PASS
96. `bash tests/governance/test_e2e_governance.sh` -> PASS
97. Final-gate orchestrator-forwarding-contract smoke sample (`assessment_request_id=d6bc537d-a47f-431a-9fa5-f7f1e2e8fd76`, `training_request_id=8034464d-ac8e-4b57-9b10-cd53c24c9004`, `chat_request_id=fe8f4f58-1fca-482b-88c8-496d9819436b`)
98. Latest verification timestamp (UTC): `2026-02-26T11:00:50Z`
99. `bash tests/functions/test_model_router_resilience_contract.sh` -> PASS
100. `bash scripts/ci/final_gate.sh` -> PASS
101. `bash tests/governance/test_docs_presence.sh` -> PASS
102. `bash tests/governance/test_e2e_governance.sh` -> PASS
103. Final-gate model-router-resilience-contract smoke sample (`assessment_request_id=0e3a603d-4d49-49a0-a076-d34db94031d7`, `training_request_id=2a022476-af0c-461a-951a-596da21c3b73`, `chat_request_id=061dc71a-b75a-4ca8-9a95-8ae0419a688c`)
104. Latest verification timestamp (UTC): `2026-02-26T11:09:21Z`
105. `bash tests/functions/test_error_response_contract.sh` -> PASS
106. `bash scripts/ci/final_gate.sh` -> PASS
107. `bash tests/governance/test_docs_presence.sh` -> PASS
108. `bash tests/governance/test_e2e_governance.sh` -> PASS
109. Final-gate error-response-contract smoke sample (`assessment_request_id=4f627be6-bb3a-4dd5-89bb-9ec984d76821`, `training_request_id=e92d88cb-856a-40fb-b749-e51ef5b13ea2`, `chat_request_id=c2c1f55d-ab00-4537-b298-a64d1e446b1c`)
110. Latest verification timestamp (UTC): `2026-02-26T12:09:45Z`
111. `bash tests/functions/test_orchestrator_conversation_bootstrap_contract.sh` -> PASS
112. `bash scripts/ci/final_gate.sh` -> PASS
113. `bash tests/governance/test_docs_presence.sh` -> PASS
114. `bash tests/governance/test_e2e_governance.sh` -> PASS
115. Final-gate orchestrator-conversation-bootstrap-contract smoke sample (`assessment_request_id=76c5d31a-687e-4632-b91b-9696b98579d8`, `training_request_id=22039cdd-42fd-4337-a639-854150e9ae24`, `chat_request_id=1161570f-8f23-4c06-a430-ba988b229239`)
116. Latest verification timestamp (UTC): `2026-02-26T12:34:14Z`
117. `bash tests/functions/test_model_router_temperature_contract.sh` -> PASS
118. `bash scripts/ci/final_gate.sh` -> PASS
119. `bash tests/governance/test_docs_presence.sh` -> PASS
120. `bash tests/governance/test_e2e_governance.sh` -> PASS
121. Final-gate model-router-temperature-contract smoke sample (`assessment_request_id=58dacdae-6481-4a15-94a2-a6582360b5ae`, `training_request_id=0b74af3c-e932-42fd-a621-a1447f79df1d`, `chat_request_id=e470c62d-3e07-4b71-9335-191195e7fa4a`)
122. Latest verification timestamp (UTC): `2026-02-26T12:44:39Z`
123. `bash tests/functions/test_request_id_lifecycle_contract.sh` -> PASS
124. `bash scripts/ci/final_gate.sh` -> PASS
125. `bash tests/governance/test_docs_presence.sh` -> PASS
126. `bash tests/governance/test_e2e_governance.sh` -> PASS
127. Final-gate request-id-lifecycle-contract smoke sample (`assessment_request_id=e63b5c53-966a-4e54-9805-feafb0f17791`, `training_request_id=a22cfa01-9a4e-4667-8fa7-be007533619a`, `chat_request_id=8487695c-56dc-4c48-b9d5-9e62aea10682`)
128. Latest verification timestamp (UTC): `2026-02-26T13:02:15Z`
129. `bash tests/functions/test_options_preflight_contract.sh` -> PASS
130. `bash scripts/ci/final_gate.sh` -> PASS
131. `bash tests/governance/test_docs_presence.sh` -> PASS
132. `bash tests/governance/test_e2e_governance.sh` -> PASS
133. Final-gate options-preflight-contract smoke sample (`assessment_request_id=1931ba96-fa48-4a07-aa37-cc353cd9a7b9`, `training_request_id=65a8c2ff-dc7f-4a16-8dcd-52405dd8c264`, `chat_request_id=b3d65f3d-2bef-4c2f-a9ba-7d10e96ff37b`)
134. Latest verification timestamp (UTC): `2026-02-26T13:27:22Z`
135. `bash tests/functions/test_sse_framing_contract.sh` -> PASS
136. `bash scripts/ci/final_gate.sh` -> PASS
137. `bash tests/governance/test_docs_presence.sh` -> PASS
138. `bash tests/governance/test_e2e_governance.sh` -> PASS
139. Final-gate sse-framing-contract smoke sample (`assessment_request_id=6c1744b5-e8d5-4fa1-86e4-4541f6bd2a8c`, `training_request_id=f64b6f02-58b6-4f14-8798-2152c1191c8d`, `chat_request_id=e422d1d7-4bd5-4e8d-a83c-2b1cfe5aa713`)
140. Latest verification timestamp (UTC): `2026-02-26T13:52:47Z`
141. `bash tests/functions/test_writeback_before_done_contract.sh` -> PASS
142. `bash scripts/ci/final_gate.sh` -> PASS
143. `bash tests/governance/test_docs_presence.sh` -> PASS
144. `bash tests/governance/test_e2e_governance.sh` -> PASS
145. Final-gate writeback-before-done-contract smoke sample (`assessment_request_id=40d64bd8-80f3-4fd6-9d67-96c1f217310f`, `training_request_id=7272ce84-9646-41bf-9aeb-3ca8c8bfa272`, `chat_request_id=04c9ccc4-ae85-4195-86f4-f6f1f7a164de`)
146. Latest verification timestamp (UTC): `2026-02-26T14:16:54Z`
147. `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS
148. `bash scripts/ci/final_gate.sh` -> PASS
149. `bash tests/governance/test_docs_presence.sh` -> PASS
150. `bash tests/governance/test_e2e_governance.sh` -> PASS
151. Final-gate Phase 2 weekly journey smoke sample (`assessment_request_id=5efea2fa-ceac-4794-adaa-1be7ba9d9eb3`, `training_advice_request_id=5c3c5127-2e92-4e7c-8dff-1568bb48b8cf`, `training_request_id=de0f24c4-cb4c-45ed-a62a-f648b62391c4`, `training_record_request_id=c30ae7c0-0004-43f9-98e6-a20846d3714d`, `dashboard_request_id=ddc2b57d-d802-46d0-894f-77a9d118b378`)
152. Phase 2 dashboard followup smoke sample (`training_request_id=2a75c851-d515-4f54-b84f-99924d08ee44`, `training_record_request_id=c1a5cef4-d9f4-4046-a665-bee8a0882e66`, `dashboard_request_id=4589d2f0-3f52-4471-a8db-9610af7ac791`)
153. `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` -> PASS
154. Latest verification timestamp (UTC): `2026-02-26T15:31:06Z`
155. `bash scripts/ci/final_gate.sh` -> PASS
156. `bash tests/governance/test_docs_presence.sh` -> PASS
157. `bash tests/governance/test_e2e_governance.sh` -> PASS
158. Final-gate Phase 2 weekly journey smoke sample (`assessment_request_id=1936d0a5-3aad-4bbf-ae26-10bcbc589245`, `training_advice_request_id=d061ba55-3471-41e2-b96f-97cc4e0f6bf5`, `training_request_id=64200afb-1f60-49e9-b90b-cfcb392d2cf6`, `training_record_request_id=4c7ccc29-c08d-4557-a72d-a09e30a7585e`, `dashboard_request_id=3a24d315-b582-42c7-ac21-c3917a576439`)
159. Phase 2 dashboard followup smoke sample (`training_request_id=c7fde7fd-3ed0-4742-bb12-2b7e472d44fb`, `training_record_request_id=a55c296e-6317-40ca-8977-97b5dffe9cd3`, `dashboard_request_id=b707c3df-d8df-4531-ab62-5a5c4dba95f3`)
160. Latest verification timestamp (UTC): `2026-02-26T15:48:56Z`
161. `bash tests/governance/test_phase3_slo_runbook_presence.sh` -> PASS
162. `bash tests/governance/test_phase3_security_ops_presence.sh` -> PASS
163. `bash tests/governance/test_phase3_cost_guardrails_presence.sh` -> PASS
164. `bash tests/governance/test_phase3_release_automation_presence.sh` -> PASS
165. `bash scripts/ci/final_gate.sh` -> PASS
166. `bash tests/governance/test_docs_presence.sh` -> PASS
167. `bash tests/governance/test_e2e_governance.sh` -> PASS
168. Final-gate Phase 3 chain smoke sample (`assessment_request_id=c156d60b-968f-4f6f-80a4-86f811a861bd`, `training_request_id=c79c70d6-cdc6-4eed-a598-1baa91e50347`, `chat_request_id=4611950e-f524-417f-8ebb-8f2488789fb4`, `dashboard_request_id=4c7b335b-b311-4595-9f0a-6c1e50aa5b05`, `idempotency_request_id=b47d5501-cf0d-4705-8287-0f44443c16bc`)
169. Final-gate Phase 2 weekly journey smoke sample (`assessment_request_id=facc4ab4-a59a-40d3-9944-6faed33cdd69`, `training_advice_request_id=b13248bd-c0f2-4dd1-996b-9d13db99637e`, `training_request_id=80286104-8c07-44a8-b2ac-be868a3f5304`, `training_record_request_id=198d05bf-76d7-40c9-afc9-26e6e02dbd91`, `dashboard_request_id=b2562c29-2f50-4e6a-9a26-7e2da4be6fcc`)
170. Phase 2 dashboard followup smoke sample (`training_request_id=47f0cc0b-5f5a-41fe-90cd-0949e3b5e5f7`, `training_record_request_id=ff425007-1034-4851-8ec0-12def25b4305`, `dashboard_request_id=d4187c25-387d-4313-b2c4-a047eaa2b513`)
171. Latest verification timestamp (UTC): `2026-02-27T01:00:20Z`
172. `bash tests/governance/test_phase3_drill_assets_presence.sh` -> PASS
173. `bash scripts/ci/final_gate.sh` -> PASS
174. `bash tests/governance/test_docs_presence.sh` -> PASS
175. `bash tests/governance/test_e2e_governance.sh` -> PASS
176. Final-gate Phase 3 chain smoke sample (`assessment_request_id=78c61f66-4f77-4b8d-98d0-b425d6cccc1f`, `training_request_id=1e58ee1f-2463-4361-ad35-cf0f7bf25b4b`, `chat_request_id=ded6c3a3-c1db-4c11-a789-76639a731e2a`, `dashboard_request_id=f2e2e9df-7aa7-464f-8615-12c437503890`, `idempotency_request_id=94af8c31-fb4d-4124-8f53-0124a332180a`)
177. Final-gate Phase 2 weekly journey smoke sample (`assessment_request_id=73c4c492-1ead-4814-8c38-99c2d40c93ef`, `training_advice_request_id=33e46daa-889d-4676-a43c-cc35305908cd`, `training_request_id=a12ce95c-b492-4cae-84bf-4d6fb2c16317`, `training_record_request_id=78a8b144-6258-4822-a144-71f79ed7269b`, `dashboard_request_id=78a11041-bdc7-41a1-9914-fbdaecd64fcb`)
178. Phase 2 dashboard followup smoke sample (`training_request_id=9f409a47-2c2c-46ef-8a2a-a3e617b51b3b`, `training_record_request_id=85d3dd73-0c64-4b2f-b02d-05c29440a631`, `dashboard_request_id=e35b6338-4d58-4b52-88bf-8c316b30de63`)
179. Final-gate retry recovery sample (`module=assessment`, `request_id=5b0580a3-b7b9-4c8f-bde7-38bf83f07cec`, `reason=WORKER_LIMIT`)
180. Latest verification timestamp (UTC): `2026-02-27T01:23:32Z`
181. `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS
182. `DRY_RUN=0 ROLLBACK_MODULE=orchestrator ROLLBACK_DRILL_RUN_FINAL_GATE=1 ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS=1 bash scripts/ops/run_phase2_rollback_drill.sh` -> PASS
183. Phase 2 rollback drill full-pass execution record: `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md` -> `phase2-rollback-drill-001-2026-02-27T23:39:40Z`
184. Phase 2 rollback drill weekly journey sample (`assessment_request_id=778f585f-107c-466e-b532-5fde7c801a47`, `training_advice_request_id=ccf6f01f-af21-4c73-bfc8-233eb00a23ca`, `training_request_id=80f36956-2cf8-4ef3-b59b-00bf0dbebc4e`, `training_record_request_id=444388c4-498b-46ad-8c9a-7eef19e441a1`, `dashboard_request_id=48f70d16-504c-4e0d-8253-8c83611775d5`)
185. Phase 2 rollback drill dashboard followup sample (`training_request_id=bd26bf35-9068-4762-b7da-97f7c401cd81`, `training_record_request_id=a4b9d8af-dc41-4721-9ea1-48e97beef4ca`, `dashboard_request_id=01efed98-8855-4fe9-80cb-52404e08f6d1`)
186. `bash tests/governance/test_phase3_drill_assets_presence.sh` -> PASS
187. `bash tests/governance/test_docs_presence.sh` -> PASS
188. `bash tests/governance/test_e2e_governance.sh` -> PASS
189. Phase 3 drill log metadata synced to execution evidence (`PHASE-3-INCIDENT-DRILL-LOG` / `PHASE-3-ROLLBACK-DRILL-LOG`)
190. Latest verification timestamp (UTC): `2026-02-27T23:39:40Z`

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
- Static live-smoke retry-observability contract gate validates helper retry/failure log fields for debugging stability
- Static live-smoke retry-reason taxonomy contract gate validates canonical reason constants and usage in retry helper
- Static live-smoke retry-reason-action contract gate validates deterministic reason-to-action branch semantics in retry helper
- Static live-smoke retry-outcome-state contract gate validates helper post-call outcome state fields for diagnostics
- Static live-smoke retry-state-reset contract gate validates per-call reset behavior and retry count state against stale carry-over
- Static live-smoke retry-cards contract gate validates cards-required terminal reason taxonomy and logging semantics
- Static live-smoke retry-request-id-trace contract gate validates per-attempt `request_ids` lineage and terminal `ORCH_LAST_REQUEST_ID` pointer semantics
- Static live-smoke retry-runtime-sanitization contract gate validates runtime fallback to default retry limits/backoff when env values are invalid
- Static live-smoke retry-backoff-timing contract gate validates exponential delay sequence and no-terminal/non-retriable sleep semantics
- Static live-smoke retry-transport-failure contract gate validates `set -e` safe curl-exit handling, transport retry semantics, and transport terminal reason writeback
- Static live-smoke retry-transport-observability contract gate validates runtime transport retry/terminal stderr log field semantics
- Static live-smoke retry-transport-exit-code contract gate validates transport retry/terminal `exit_code` diagnostics and terminal `ORCH_LAST_RESPONSE` marker writeback
- Static functions auth/body-parse contract gate validates request authentication, child-access guard, and single-pass `req.json()` consumption across 7 execution-chain entry files
- Static shared reliability contract gate validates shared service-client singleton reuse and RPC-only finalize writeback path (`finalize_writeback`)
- Static orchestrator forwarding contract gate validates downstream forwarding URL/auth/payload semantics, idempotency query constraints, and SSE proxy response behavior
- Static model-router resilience contract gate validates provider-pick semantics, dual-provider fallback structure, non-streaming completion config, and doubao model guard behavior
- Static error-response contract gate validates BAD_REQUEST/AUTH_FORBIDDEN/INTERNAL_ERROR SSE semantics and canonical HTTP status mapping across execution-chain functions
- Static orchestrator conversation bootstrap contract gate validates conversation auto-create defaults and ingress user-message persistence semantics in orchestrator
- Static model-router temperature contract gate validates caller-provided temperature semantics in model-router (`options.temperature` honored in Kimi and Doubao paths)
- Static request-id lifecycle contract gate validates module-level request_id inheritance, finalizeWriteback passthrough, and done-event request_id echo semantics
- Static options preflight contract gate validates canonical `OPTIONS` guard and null preflight SSE-header response semantics across 7 execution-chain entry files
- Static SSE framing contract gate validates `stream_start -> delta -> done` event presence and lexical order across 6 execution modules
- Static writeback-before-done contract gate validates `finalizeWriteback` executes before terminal SSE `done` across 6 execution modules
- Governance release artifact gate validates Phase 2 release checklist and rollback drill log presence/required clauses
- Phase 2 live scenario gates validate weekly parent journey and dashboard follow-up request-id trace + writeback consistency
- Phase 3 governance gates validate SLO/SLI baseline, operations runbook, security operations, cost guardrails, and release automation policy artifacts
- Phase 3 drill assets gate validates executable incident/rollback drill scripts and drill log forms
- Live idempotency gate validates duplicate request short-circuit and single completion operation log behavior
- Contract generation confirms `Module Contracts (7)` for current execution-chain modules

## Current Status

- Tracked baseline/phase gaps (`GAP-0001` ~ `GAP-0005`) are currently marked `done` in `docs/governance/GAP-REGISTER.md`.
- Future modules must be added to `governance/agent-contract/source/contract.yaml` required list before release.
- CI gate for DB rebuild + execution-chain smoke is active in `.github/workflows/db-rebuild-and-chain-smoke.yml`.
