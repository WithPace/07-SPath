# Functions Request ID Lifecycle Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Lock module-level `request_id` lifecycle semantics for traceability from request intake to finalize writeback and SSE completion output.

**Architecture:** Add one static functions contract test across six module entry files, enforcing three invariants: payload request_id inheritance, finalizeWriteback requestId passthrough, and done-event request_id echo.

**Tech Stack:** Bash + ripgrep static checks, existing governance/final gate.

### Task 1: RED - add request_id lifecycle contract test

**Files:**
- Create: `tests/functions/test_request_id_lifecycle_contract.sh`

**Step 1: Write failing test first**

- For each module file (`chat-casual`, `assessment`, `training`, `training-advice`, `training-record`, `dashboard`) assert:
  - `requestId = payload.request_id || requestId;`
  - `await finalizeWriteback({` exists and includes `requestId,`
  - `sseEvent("done"` exists and includes `request_id: requestId`

**Step 2: Run RED**

Run:
- `bash tests/functions/test_request_id_lifecycle_contract.sh`

Expected:
- FAIL because script does not exist yet.

### Task 2: GREEN - implement static gate

**Files:**
- Create: `tests/functions/test_request_id_lifecycle_contract.sh`

**Step 1: Add deterministic checks**

- Add explicit fail message with file path and missing rule.

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_request_id_lifecycle_contract.sh`
- `bash tests/functions/test_orchestrator_forwarding_contract.sh`
- `bash tests/functions/test_error_response_contract.sh`

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

- Append request_id lifecycle contract pass lines.
- Append latest full gate and UTC timestamp.
- Add assertion bullet for module request_id lifecycle contract.

**Step 2: Commit**

```bash
git add tests/functions/test_request_id_lifecycle_contract.sh \
  docs/plans/2026-02-26-functions-request-id-lifecycle-contract-design.md \
  docs/plans/2026-02-26-functions-request-id-lifecycle-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add request-id lifecycle contract gate"
```
