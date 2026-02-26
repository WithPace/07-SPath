# Shared Reliability Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Guard shared reliability primitives against regression by enforcing singleton service-client reuse and RPC-based finalize writeback.

**Architecture:** Add one static functions contract test that validates `_shared/auth.ts` and `_shared/finalize.ts` invariants through deterministic source checks. No runtime behavior changes; governance guard only.

**Tech Stack:** Bash + ripgrep static contract checks, existing CI/final gate flow.

### Task 1: RED - add shared reliability contract test

**Files:**
- Create: `tests/functions/test_shared_reliability_contract.sh`

**Step 1: Write failing test first**

- Test script should enforce:
  - `_shared/auth.ts` contains singleton cache declaration and reuse:
    - `let _serviceClient: SupabaseClient | null = null;`
    - `if (_serviceClient) return _serviceClient;`
    - `_serviceClient = createClient(...)`
  - `_shared/finalize.ts` contains:
    - `client.rpc("finalize_writeback", ...)`
  - `_shared/finalize.ts` does NOT contain direct writes:
    - `.from("snapshot_refresh_events")`
    - `.from("operation_logs")`

**Step 2: Run RED**

Run:
- `bash tests/functions/test_shared_reliability_contract.sh`

Expected:
- FAIL before file exists.

### Task 2: GREEN - minimal static gate implementation

**Files:**
- Create: `tests/functions/test_shared_reliability_contract.sh`

**Step 1: Implement deterministic checks**

- Add explicit fail messages for each violated rule.

**Step 2: Verify test passes**

Run:
- `bash tests/functions/test_shared_reliability_contract.sh`

Expected:
- PASS.

### Task 3: Verification

**Step 1: Focused verification**

Run:
- `bash tests/functions/test_shared_reliability_contract.sh`
- `bash tests/functions/test_shared_modules.sh`
- `bash tests/functions/test_auth_and_body_parse_contract.sh`

Expected:
- PASS.

**Step 2: Full verification**

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

- Append new contract gate command pass lines.
- Append latest final_gate pass evidence and UTC timestamp.
- Add assertion bullet for shared reliability contract.

**Step 2: Commit**

```bash
git add tests/functions/test_shared_reliability_contract.sh \
  docs/plans/2026-02-26-shared-reliability-contract-design.md \
  docs/plans/2026-02-26-shared-reliability-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add shared reliability contract gate"
```
