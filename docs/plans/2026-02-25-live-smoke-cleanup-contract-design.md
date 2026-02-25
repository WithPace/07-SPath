# Live Smoke Cleanup Contract Gate Design

## Context

- Live e2e scripts create real users/children/care-team data in official Supabase.
- Cleanup correctness is essential to avoid data pollution and flaky follow-up runs.
- Existing guard `test_live_smoke_cleanup_presence.sh` checks only one file (`chat_casual`).

## Problem

- Missing cleanup hooks in any other live script could bypass governance checks.
- Current gate is too narrow and can miss regressions in new/updated live scripts.

## Options

### Option A: Keep single-file cleanup guard

Trade-offs:
- Pros: zero work.
- Cons: weak governance coverage.

### Option B (Selected): Add all-script cleanup contract gate

- Add a new e2e static contract test that iterates all live scripts and asserts:
  - `cleanup()` exists
  - `trap cleanup EXIT` exists
  - admin-user cleanup endpoint exists
  - delete operations exist

Trade-offs:
- Pros: broad protection, low complexity, no runtime behavior changes.
- Cons: one more static test to maintain.

### Option C: Centralize cleanup helper and refactor all scripts

Trade-offs:
- Pros: DRY cleanup logic.
- Cons: larger refactor risk for little immediate governance gain.

## Chosen Design

- Implement Option B with a dedicated `tests/e2e/test_live_smoke_cleanup_contract.sh`.
- Keep existing single-file check unchanged; new gate adds cross-script enforcement.
