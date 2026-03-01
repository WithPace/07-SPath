# Deploy Go-Live Execution Chain Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an auditable, script-driven deployment and go-live sequence for all project Supabase Edge Functions.

**Architecture:** Keep release operations as shell scripts under `scripts/ci`, enforce presence and command coverage with CI contract tests under `tests/ci`, and document operator workflow in governance docs. Use `DRY_RUN` to make every critical step previewable before live execution.

**Tech Stack:** Bash, Supabase CLI, repository governance test suite.

### Task 1: Deploy Script Contract Coverage

**Files:**
- Modify: `scripts/ci/deploy_functions.sh`
- Test: `tests/ci/test_deploy_release_scripts_presence.sh`

**Step 1: Write the failing test**

Ensure the test asserts:
- script exists and is executable
- script includes `SUPABASE_PROJECT_REF` handling
- all module deploy commands are present
- `DRY_RUN` behavior is supported

**Step 2: Run test to verify it fails**

Run: `bash tests/ci/test_deploy_release_scripts_presence.sh`  
Expected: FAIL with missing executable or missing command patterns.

**Step 3: Write minimal implementation**

Implement explicit deploy commands in `scripts/ci/deploy_functions.sh`:
- `orchestrator`
- `chat-casual`
- `assessment`
- `training`
- `training-advice`
- `training-record`
- `dashboard`

**Step 4: Run test to verify it passes**

Run: `bash tests/ci/test_deploy_release_scripts_presence.sh`  
Expected: PASS with `deploy/release scripts present`.

**Step 5: Commit**

```bash
git add scripts/ci/deploy_functions.sh tests/ci/test_deploy_release_scripts_presence.sh
git commit -m "feat(ci): enforce edge-function deploy script contract"
```

### Task 2: Release Go-Live Script

**Files:**
- Create: `scripts/ci/release_go_live.sh`
- Test: `tests/ci/test_deploy_release_scripts_presence.sh`

**Step 1: Write the failing test**

Add assertions for:
- `scripts/ci/release_go_live.sh` exists and is executable
- references `scripts/ci/deploy_functions.sh`
- runs `bash scripts/ci/final_gate.sh`
- runs governance docs/e2e gates
- supports `DRY_RUN`

**Step 2: Run test to verify it fails**

Run: `bash tests/ci/test_deploy_release_scripts_presence.sh`  
Expected: FAIL with `missing release go-live script`.

**Step 3: Write minimal implementation**

Create `scripts/ci/release_go_live.sh` to run:
1. deploy script
2. final gate
3. docs presence gate
4. governance e2e gate

**Step 4: Run test to verify it passes**

Run: `bash tests/ci/test_deploy_release_scripts_presence.sh`  
Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/ci/release_go_live.sh tests/ci/test_deploy_release_scripts_presence.sh
git commit -m "feat(ci): add go-live release gate script"
```

### Task 3: Governance Runbook Integration

**Files:**
- Create: `docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md`
- Modify: `docs/governance/PHASE-3-RELEASE-AUTOMATION.md`
- Modify: `tests/governance/test_docs_presence.sh`

**Step 1: Write the failing test**

Require runbook presence in `tests/governance/test_docs_presence.sh`.

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_docs_presence.sh`  
Expected: FAIL until runbook exists.

**Step 3: Write minimal implementation**

Add runbook with:
- prerequisites and required env vars
- dry-run workflow
- deploy-only workflow
- full release workflow
- rollback drill commands
- note about missing frontend simulator scope in this repo

**Step 4: Run test to verify it passes**

Run:
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: both PASS.

**Step 5: Commit**

```bash
git add docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md docs/governance/PHASE-3-RELEASE-AUTOMATION.md tests/governance/test_docs_presence.sh
git commit -m "docs(governance): add deploy-test-go-live runbook"
```
