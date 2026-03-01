# Phase 4 Frontend Delivery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a production-ready parent frontend in a separate frontend repository with full test coverage and a launch-ready release gate aligned with backend governance.

**Architecture:** Keep backend/governance in `starpath` and build frontend in `starpath-frontend`. Enforce cross-repo release handshake: backend strict go-live + frontend strict final gate must both pass before production promotion.

**Tech Stack:** Next.js + TypeScript + Zustand + Supabase client + Vitest + Testing Library + Playwright + GitHub Actions.

## Task 1: Create Phase 4 Governance Baseline (Current Repo)

**Files:**
- Create: `docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md`
- Create: `docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md`
- Create: `tests/governance/test_phase4_frontend_governance_presence.sh`
- Modify: `tests/governance/test_docs_presence.sh`

**Step 1: Write failing governance test**

Run:
- `bash tests/governance/test_phase4_frontend_governance_presence.sh`

Expected:
- FAIL before docs exist.

**Step 2: Implement minimal docs**

- Add checklist entry/exit criteria, frontend gate requirements, cross-repo sign-off fields.
- Add release record identity/evidence/rollback sections for frontend release snapshots.

**Step 3: Integrate docs presence gate**

- Require new Phase 4 docs in `tests/governance/test_docs_presence.sh`.

**Step 4: Verify**

Run:
- `bash tests/governance/test_phase4_frontend_governance_presence.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

**Step 5: Commit**

```bash
git add docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md tests/governance/test_phase4_frontend_governance_presence.sh tests/governance/test_docs_presence.sh
git commit -m "feat(governance): add phase4 frontend delivery governance baseline"
```

## Task 2: Define Frontend Contract Fixture Pack (Current Repo)

**Files:**
- Create: `docs/governance/PHASE-4-FRONTEND-CONTRACT-FIXTURES.md`
- Create: `tests/functions/test_phase4_frontend_contract_fixtures_presence.sh`

**Step 1: Write failing fixture contract test**

Run:
- `bash tests/functions/test_phase4_frontend_contract_fixtures_presence.sh`

Expected:
- FAIL before fixture spec exists.

**Step 2: Implement minimal fixture spec**

- Enumerate required frontend-consumed payload fixtures:
  - chat-casual done payload
  - assessment done payload
  - training/training-advice/training-record done payload
  - dashboard cards delta + done payload
  - retry/transport error event examples

**Step 3: Verify**

Run:
- `bash tests/functions/test_phase4_frontend_contract_fixtures_presence.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add docs/governance/PHASE-4-FRONTEND-CONTRACT-FIXTURES.md tests/functions/test_phase4_frontend_contract_fixtures_presence.sh
git commit -m "docs(contract): define phase4 frontend fixture pack"
```

## Task 3: Bootstrap Frontend Repo Skeleton (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `next.config.ts`
- Create: `src/app/layout.tsx`
- Create: `src/app/page.tsx`
- Create: `src/lib/env.ts`
- Create: `.github/workflows/frontend-final-gate.yml`

**Step 1: Write failing CI smoke test**

Run (frontend repo):
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`

Expected:
- FAIL before scripts and setup exist.

**Step 2: Implement minimal bootstrap**

- Add scripts for lint/typecheck/test/build.
- Add env validation module requiring Supabase URL/key and API base.

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
git commit -m "chore(frontend): bootstrap nextjs repository with ci gate skeleton"
```

## Task 4: Implement Orchestrator Client + SSE Parser with TDD (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `src/lib/api/orchestrator-client.ts`
- Create: `src/lib/sse/parse-events.ts`
- Create: `src/lib/sse/parse-events.test.ts`
- Create: `src/lib/api/orchestrator-client.test.ts`

**Step 1: Write failing parser tests**

Run:
- `pnpm vitest src/lib/sse/parse-events.test.ts`

Expected:
- FAIL before parser exists.

**Step 2: Write minimal parser + client implementation**

- Parse delta/done/error frames.
- Preserve `request_id`, `module`, `reason`, and `cards` payload fields.

**Step 3: Verify**

Run:
- `pnpm vitest src/lib/sse/parse-events.test.ts src/lib/api/orchestrator-client.test.ts`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/lib/api src/lib/sse
git commit -m "feat(frontend): add orchestrator sse client and parser contracts"
```

## Task 5: Parent MVP Screens and Core Flows (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `src/app/(parent)/chat/page.tsx`
- Create: `src/app/(parent)/dashboard/page.tsx`
- Create: `src/components/chat/*`
- Create: `src/components/cards/*`
- Create: `src/stores/chat-store.ts`
- Create: `src/stores/dashboard-store.ts`
- Create: `src/components/chat/chat-flow.test.tsx`
- Create: `src/components/cards/dashboard-cards.test.tsx`

**Step 1: Write failing component tests**

Run:
- `pnpm vitest src/components/chat/chat-flow.test.tsx src/components/cards/dashboard-cards.test.tsx`

Expected:
- FAIL before components exist.

**Step 2: Implement minimal UI and store logic**

- Parent chat input + timeline + streaming output.
- Dashboard cards rendering + empty/loading/error states.
- Retry action for transient failures.

**Step 3: Verify**

Run:
- `pnpm vitest src/components/chat/chat-flow.test.tsx src/components/cards/dashboard-cards.test.tsx`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add src/app src/components src/stores
git commit -m "feat(frontend): implement parent mvp chat and dashboard flows"
```

## Task 6: Frontend Contract + E2E Live Test Harness (`../starpath-frontend`)

**Files (frontend repo):**
- Create: `tests/contract/orchestrator-contract.test.ts`
- Create: `tests/e2e/parent-weekly-journey.spec.ts`
- Create: `tests/e2e/parent-dashboard-followup.spec.ts`
- Create: `playwright.config.ts`
- Create: `scripts/ci/frontend_final_gate.sh`

**Step 1: Write failing contract/e2e tests**

Run:
- `pnpm vitest tests/contract/orchestrator-contract.test.ts`
- `pnpm playwright test tests/e2e/parent-weekly-journey.spec.ts`

Expected:
- FAIL before fixtures and flows are wired.

**Step 2: Implement minimal harness**

- Load fixture pack aligned to backend contract catalog.
- Add deterministic retries and stable selectors for e2e.

**Step 3: Verify**

Run:
- `pnpm vitest tests/contract/orchestrator-contract.test.ts`
- `pnpm playwright test`
- `bash scripts/ci/frontend_final_gate.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add tests playwright.config.ts scripts/ci/frontend_final_gate.sh
git commit -m "test(frontend): add contract and e2e gate for parent mvp"
```

## Task 7: Cross-Repo Launch Handshake and Evidence (Both Repos)

**Files (backend repo):**
- Modify: `docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md`
- Modify: `docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md`
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`

**Files (frontend repo):**
- Create/Modify: `docs/governance/FRONTEND-RELEASE-RECORD.md`

**Step 1: Write failing governance checks**

Run (backend repo):
- `bash tests/governance/test_phase4_frontend_governance_presence.sh`

Expected:
- FAIL before frontend evidence references are added.

**Step 2: Implement handshake evidence fields**

- Record frontend commit SHA, gate command outputs, environment, rollback reference.
- Reference backend strict release evidence ID for traceability.

**Step 3: Verify**

Run (frontend repo):
- `bash scripts/ci/frontend_final_gate.sh`

Run (backend repo):
- `bash scripts/ci/release_go_live.sh`
- `bash tests/governance/test_phase4_frontend_governance_presence.sh`
- `bash tests/governance/test_docs_presence.sh`

Expected:
- PASS.

**Step 4: Commit**

```bash
git add docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md docs/governance/REBUILD-VERIFICATION-2026-02-23.md
git commit -m "chore(governance): close phase4 frontend launch handshake evidence"
```

## Task 8: Final Readiness Verification

**Step 1: Frontend final gate**

Run:
- `bash ../starpath-frontend/scripts/ci/frontend_final_gate.sh`

Expected:
- PASS.

**Step 2: Backend strict go-live gate**

Run:
- `bash scripts/ci/release_go_live.sh`

Expected:
- PASS.

**Step 3: Full backend gate**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

**Step 4: Release report update**

- Append final UTC timestamp, frontend and backend release identifiers, and sample request IDs to governance verification docs.

## Task 9: Commit Strategy

Commit per task with small increments:

```bash
git add <task files>
git commit -m "<scope>: <phase4 increment>"
```

Final closeout commit in backend repo:

```bash
git add docs/governance/REBUILD-VERIFICATION-2026-02-23.md docs/governance/PHASE-4-FRONTEND-DELIVERY-CHECKLIST.md docs/governance/PHASE-4-FRONTEND-RELEASE-RECORD.md
git commit -m "chore(phase4): finalize frontend delivery and launch readiness evidence"
```
