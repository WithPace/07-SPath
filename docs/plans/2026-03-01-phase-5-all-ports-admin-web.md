# Phase 5 Full Ports + Admin Web Delivery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver all user ports (`parent`, `doctor`, `teacher`, `org_admin`) and operations management web with production-grade governance, test gates, and launch evidence.

**Architecture:** Use three-repo execution model. `starpath` remains backend/governance authority, `starpath-frontend` delivers user ports, and `starpath-admin-web` delivers management web. Release promotion requires strict gate pass from all three repositories plus sign-off closure.

**Tech Stack:** Supabase Edge Functions + TypeScript + Bash governance gates + Next.js + Vitest + Playwright + GitHub Actions.

## Task 1: Phase 5 Governance Baseline (Backend Repo)

**Files:**
- Create: `docs/governance/PHASE-5-DELIVERY-CHECKLIST.md`
- Create: `docs/governance/PHASE-5-RELEASE-RECORD.md`
- Create: `tests/governance/test_phase5_governance_presence.sh`
- Modify: `tests/governance/test_docs_presence.sh`

**Step 1: RED**

Run:
- `bash tests/governance/test_phase5_governance_presence.sh`

Expected:
- FAIL before Phase 5 governance docs exist.

**Step 2: GREEN**

- Add checklist with entry/exit criteria, role matrix, and cross-repo sign-off table.
- Add release record with identity, gate outputs, rollback reference, evidence ledger.

**Step 3: Verify**

Run:
- `bash tests/governance/test_phase5_governance_presence.sh`
- `bash tests/governance/test_docs_presence.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add docs/governance/PHASE-5-DELIVERY-CHECKLIST.md docs/governance/PHASE-5-RELEASE-RECORD.md tests/governance/test_phase5_governance_presence.sh tests/governance/test_docs_presence.sh
git commit -m "feat(governance): establish phase5 delivery baseline"
```

## Task 2: Role Contract Catalog and Fixture Governance (Backend Repo)

**Files:**
- Create: `docs/governance/PHASE-5-ROLE-CONTRACT-CATALOG.md`
- Create: `docs/governance/PHASE-5-ROLE-CONTRACT-FIXTURES.md`
- Create: `tests/functions/test_phase5_role_contract_catalog_presence.sh`

**Step 1: RED**

Run:
- `bash tests/functions/test_phase5_role_contract_catalog_presence.sh`

Expected:
- FAIL before role contract docs exist.

**Step 2: GREEN**

- Define payload contracts for each role and module.
- Define fixture consumption requirements for both frontend repos.

**Step 3: Verify**

Run:
- `bash tests/functions/test_phase5_role_contract_catalog_presence.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add docs/governance/PHASE-5-ROLE-CONTRACT-CATALOG.md docs/governance/PHASE-5-ROLE-CONTRACT-FIXTURES.md tests/functions/test_phase5_role_contract_catalog_presence.sh
git commit -m "docs(contract): define phase5 role contract catalog and fixtures"
```

## Task 3: Backend Role and RLS Enforcement Expansion

**Files:**
- Modify: `supabase/functions/dashboard/index.ts`
- Modify: `supabase/functions/orchestrator/index.ts`
- Create: `tests/functions/test_phase5_dashboard_role_matrix_contract.sh`
- Create: `tests/db/test_phase5_rls_role_matrix.sh`
- Create: `tests/e2e/test_phase5_doctor_teacher_org_journeys_live.sh`

**Step 1: RED**

Run:
- `bash tests/functions/test_phase5_dashboard_role_matrix_contract.sh`
- `bash tests/db/test_phase5_rls_role_matrix.sh`

Expected:
- FAIL before role expansion is implemented.

**Step 2: GREEN**

- Expand dashboard role handling from parent-only to full role matrix.
- Add explicit authorization and role-mapping checks.
- Add/adjust RLS policy validation for all role paths.

**Step 3: Verify**

Run:
- `bash tests/functions/test_phase5_dashboard_role_matrix_contract.sh`
- `bash tests/db/test_phase5_rls_role_matrix.sh`
- `bash tests/e2e/test_phase5_doctor_teacher_org_journeys_live.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add supabase/functions/dashboard/index.ts supabase/functions/orchestrator/index.ts tests/functions/test_phase5_dashboard_role_matrix_contract.sh tests/db/test_phase5_rls_role_matrix.sh tests/e2e/test_phase5_doctor_teacher_org_journeys_live.sh
git commit -m "feat(role): extend backend contracts and rls for phase5 role matrix"
```

## Task 4: Bootstrap User Ports Repo (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `src/app/(parent)/chat/page.tsx`
- Create: `src/app/(doctor)/dashboard/page.tsx`
- Create: `src/app/(teacher)/dashboard/page.tsx`
- Create: `src/app/(org-admin)/dashboard/page.tsx`
- Create: `scripts/ci/frontend_final_gate.sh`

**Step 1: RED**

Run (frontend repo):
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`

Expected:
- FAIL before baseline app and scripts exist.

**Step 2: GREEN**

- Bootstrap Next.js app structure and role route groups.
- Add env guard and shared role-aware client boundary.

**Step 3: Verify**

Run:
- `pnpm install`
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`
- `pnpm build`

Expected:
- PASS.

**Step 4: Commit (frontend repo)**

```bash
git add .
git commit -m "chore(frontend): bootstrap phase5 multi-role user ports"
```

## Task 5: Parent Port Production Completion (`../starpath-frontend`)

**Files (frontend repo):**
- Modify: `src/app/(parent)/chat/page.tsx`
- Create: `src/app/(parent)/dashboard/page.tsx`
- Create: `tests/e2e/parent-weekly-journey.spec.ts`
- Create: `tests/contract/parent-contract.spec.ts`

**Step 1: RED**

Run:
- `pnpm vitest tests/contract/parent-contract.spec.ts`
- `pnpm playwright test tests/e2e/parent-weekly-journey.spec.ts`

Expected:
- FAIL before contracts and e2e journey are complete.

**Step 2: GREEN**

- Finalize parent chat/dashboard UX and retry behaviors.
- Wire parent flows to role contract fixtures.

**Step 3: Verify**

Run:
- `pnpm vitest tests/contract/parent-contract.spec.ts`
- `pnpm playwright test tests/e2e/parent-weekly-journey.spec.ts`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/app/(parent) tests/contract/parent-contract.spec.ts tests/e2e/parent-weekly-journey.spec.ts
git commit -m "feat(frontend): complete parent production flows for phase5"
```

## Task 6: Doctor Port Delivery (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `src/app/(doctor)/chat/page.tsx`
- Modify: `src/app/(doctor)/dashboard/page.tsx`
- Create: `tests/contract/doctor-contract.spec.ts`
- Create: `tests/e2e/doctor-followup-journey.spec.ts`

**Step 1: RED**

Run:
- `pnpm vitest tests/contract/doctor-contract.spec.ts`
- `pnpm playwright test tests/e2e/doctor-followup-journey.spec.ts`

Expected:
- FAIL before doctor role implementation exists.

**Step 2: GREEN**

- Implement doctor-specific card mapping and workflow actions.
- Enforce role-scoped query/filter behavior.

**Step 3: Verify**

Run:
- `pnpm vitest tests/contract/doctor-contract.spec.ts`
- `pnpm playwright test tests/e2e/doctor-followup-journey.spec.ts`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/app/(doctor) tests/contract/doctor-contract.spec.ts tests/e2e/doctor-followup-journey.spec.ts
git commit -m "feat(frontend): deliver doctor port journeys and contracts"
```

## Task 7: Teacher Port Delivery (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `src/app/(teacher)/chat/page.tsx`
- Modify: `src/app/(teacher)/dashboard/page.tsx`
- Create: `tests/contract/teacher-contract.spec.ts`
- Create: `tests/e2e/teacher-training-journey.spec.ts`

**Step 1: RED**

Run:
- `pnpm vitest tests/contract/teacher-contract.spec.ts`
- `pnpm playwright test tests/e2e/teacher-training-journey.spec.ts`

Expected:
- FAIL before teacher role implementation exists.

**Step 2: GREEN**

- Implement teacher-specific views (training progress, classroom/session context).
- Enforce teacher scope in API request builder and UI state.

**Step 3: Verify**

Run:
- `pnpm vitest tests/contract/teacher-contract.spec.ts`
- `pnpm playwright test tests/e2e/teacher-training-journey.spec.ts`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/app/(teacher) tests/contract/teacher-contract.spec.ts tests/e2e/teacher-training-journey.spec.ts
git commit -m "feat(frontend): deliver teacher port journeys and contracts"
```

## Task 8: Org Admin Port Delivery (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `src/app/(org-admin)/members/page.tsx`
- Modify: `src/app/(org-admin)/dashboard/page.tsx`
- Create: `tests/contract/org-admin-contract.spec.ts`
- Create: `tests/e2e/org-admin-member-management.spec.ts`

**Step 1: RED**

Run:
- `pnpm vitest tests/contract/org-admin-contract.spec.ts`
- `pnpm playwright test tests/e2e/org-admin-member-management.spec.ts`

Expected:
- FAIL before org admin workflows are implemented.

**Step 2: GREEN**

- Implement org admin roster/permission and org analytics surfaces.
- Enforce org-boundary checks on list/detail actions.

**Step 3: Verify**

Run:
- `pnpm vitest tests/contract/org-admin-contract.spec.ts`
- `pnpm playwright test tests/e2e/org-admin-member-management.spec.ts`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/app/(org-admin) tests/contract/org-admin-contract.spec.ts tests/e2e/org-admin-member-management.spec.ts
git commit -m "feat(frontend): deliver org admin port journeys and contracts"
```

## Task 9: Bootstrap Admin Web Repo (`../starpath-admin-web`)

**Files (admin repo):**
- Create: `package.json`
- Create: `src/app/dashboard/page.tsx`
- Create: `src/app/users/page.tsx`
- Create: `src/app/content/page.tsx`
- Create: `src/app/ai-ops/page.tsx`
- Create: `scripts/ci/admin_web_final_gate.sh`

**Step 1: RED**

Run (admin repo):
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`

Expected:
- FAIL before bootstrap exists.

**Step 2: GREEN**

- Bootstrap admin web routing and guard layer.
- Add environment and role preflight checks.

**Step 3: Verify**

Run:
- `pnpm install`
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`
- `pnpm build`

Expected:
- PASS.

**Step 4: Commit (admin repo)**

```bash
git add .
git commit -m "chore(admin): bootstrap management web and gate skeleton"
```

## Task 10: Admin Web Core Domain Delivery (`../starpath-admin-web`)

**Files (admin repo):**
- Create: `src/modules/user-management/*`
- Create: `src/modules/subscription/*`
- Create: `src/modules/content-prompt/*`
- Create: `src/modules/ai-ops/*`
- Create: `tests/e2e/admin-ops-journey.spec.ts`
- Create: `tests/security/admin-rbac.spec.ts`

**Step 1: RED**

Run:
- `pnpm vitest tests/security/admin-rbac.spec.ts`
- `pnpm playwright test tests/e2e/admin-ops-journey.spec.ts`

Expected:
- FAIL before admin domains and RBAC are complete.

**Step 2: GREEN**

- Deliver admin domain modules aligned with `docs/10-管理后台设计文档.md`.
- Implement privileged action audit hooks and deny-by-default permissions.

**Step 3: Verify**

Run:
- `pnpm vitest tests/security/admin-rbac.spec.ts`
- `pnpm playwright test tests/e2e/admin-ops-journey.spec.ts`
- `bash scripts/ci/admin_web_final_gate.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/modules tests scripts/ci/admin_web_final_gate.sh
git commit -m "feat(admin): deliver management web core domains with rbac tests"
```

## Task 11: Cross-Repo Handshake and Governance Evidence

**Files (backend repo):**
- Modify: `docs/governance/PHASE-5-DELIVERY-CHECKLIST.md`
- Modify: `docs/governance/PHASE-5-RELEASE-RECORD.md`
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/GAP-REGISTER.md`

**Step 1: RED**

Run (backend repo):
- `bash tests/governance/test_phase5_governance_presence.sh`

Expected:
- FAIL before frontend/admin evidence references are complete.

**Step 2: GREEN**

- Record frontend and admin commit SHA, gate outputs, rollback links.
- Update gap register states from `missing` to resolved/accepted risk where applicable.

**Step 3: Verify**

Run:
- `bash scripts/ci/release_go_live.sh`
- `bash ../starpath-frontend/scripts/ci/frontend_final_gate.sh`
- `bash ../starpath-admin-web/scripts/ci/admin_web_final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add docs/governance/PHASE-5-DELIVERY-CHECKLIST.md docs/governance/PHASE-5-RELEASE-RECORD.md docs/governance/REBUILD-VERIFICATION-2026-02-23.md docs/governance/GAP-REGISTER.md
git commit -m "chore(governance): close phase5 cross-repo release handshake evidence"
```

## Task 12: Final Phase 5 Closeout

**Step 1: Final verification sweep**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash scripts/ci/release_go_live.sh`
- `bash ../starpath-frontend/scripts/ci/frontend_final_gate.sh`
- `bash ../starpath-admin-web/scripts/ci/admin_web_final_gate.sh`

Expected:
- PASS.

**Step 2: Report update**

- Append final UTC timestamp, release ids, request-id samples, and sign-off closure.

**Step 3: Final commit**

```bash
git add docs/governance/REBUILD-VERIFICATION-2026-02-23.md docs/governance/PHASE-5-DELIVERY-CHECKLIST.md docs/governance/PHASE-5-RELEASE-RECORD.md
git commit -m "chore(phase5): finalize full ports and admin web launch readiness"
```
