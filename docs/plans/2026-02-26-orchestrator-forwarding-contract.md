# Orchestrator Forwarding Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Lock orchestrator-to-module forwarding semantics with a deterministic static contract gate.

**Architecture:** Add one function-level static test that validates the orchestrator forwarding URL/auth/body contract and idempotency short-circuit query invariants. Keep changes test-only (plus governance evidence/docs updates).

**Tech Stack:** Bash + ripgrep static checks, existing CI/final gate.

### Task 1: RED - add orchestrator forwarding contract test

**Files:**
- Create: `tests/functions/test_orchestrator_forwarding_contract.sh`

**Step 1: Write failing test first**

- Enforce in `supabase/functions/orchestrator/index.ts`:
  - `const fnUrl = \`${Deno.env.get("SUPABASE_URL")}/functions/v1/${route.functionName}\`;`
  - downstream `fetch(fnUrl, ...)` exists.
  - header passthrough uses `Authorization: getAuthHeader(req)`.
  - forwarding body includes:
    - `child_id`
    - `message`
    - `conversation_id`
    - `request_id`
    - `module`
    - `orchestrator_latency_ms`
  - idempotency query keeps:
    - `.eq("request_id", requestId)`
    - `.eq("action_name", route.actionName)`
    - `.eq("final_status", "completed")`
  - successful path proxies downstream stream:
    - `new Response(fnResp.body, { ...headers: SSE_HEADERS ... })`

**Step 2: Run RED**

Run:
- `bash tests/functions/test_orchestrator_forwarding_contract.sh`

Expected:
- FAIL before file exists.

### Task 2: GREEN - implement static forwarding contract gate

**Files:**
- Create: `tests/functions/test_orchestrator_forwarding_contract.sh`

**Step 1: Add deterministic checks**

- Use grep/rg with explicit failure messages.

**Step 2: Verify focused checks**

Run:
- `bash tests/functions/test_orchestrator_forwarding_contract.sh`
- `bash tests/functions/test_orchestrator_route_contract.sh`
- `bash tests/functions/test_auth_and_body_parse_contract.sh`

Expected:
- PASS.

### Task 3: Full verification

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

### Task 4: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

- Append new forwarding contract pass lines.
- Append latest full-gate pass lines + UTC timestamp.
- Add assertion bullet for forwarding contract.

**Step 2: Commit**

```bash
git add tests/functions/test_orchestrator_forwarding_contract.sh \
  docs/plans/2026-02-26-orchestrator-forwarding-contract-design.md \
  docs/plans/2026-02-26-orchestrator-forwarding-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add orchestrator forwarding contract gate"
```
