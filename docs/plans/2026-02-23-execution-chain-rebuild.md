# Execution Chain Rebuild (Supabase + Live Model) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the full StarPath database schema via Supabase CLI and deliver a live `orchestrator -> chat-casual` execution chain with transactional writeback and auditable evidence.

**Architecture:** Use a schema-freeze-first workflow to eliminate document drift before destructive rebuild. Apply one main SQL migration (31 tables + constraints + indexes + RLS + triggers), then implement minimal Edge Functions (`orchestrator`, `chat-casual`) with shared auth/model/finalize modules. Validate end-to-end with automated shell checks, schema dump assertions, and live smoke tests against Supabase + Doubao/Kimi.

**Tech Stack:** Supabase CLI, PostgreSQL SQL, Deno TypeScript (Edge Functions), Bash, curl.

### Task 1: Bootstrap Supabase Workspace and Preflight Checks

**Files:**
- Create: `supabase/config.toml` (via CLI)
- Create: `tests/db/test_00_preflight.sh`
- Create: `scripts/db/preflight.sh`
- Test: `tests/db/test_00_preflight.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

test -f .env
for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY DOUBAO_API_KEY KIMI_API_KEY; do
  grep -q "^${key}=" .env
done
test -f supabase/config.toml
echo "preflight prerequisites present"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_00_preflight.sh`  
Expected: FAIL due missing `supabase/config.toml`.

**Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

supabase init
supabase link --project-ref "$SUPABASE_PROJECT_REF"
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_00_preflight.sh`  
Expected: PASS with `preflight prerequisites present`.

**Step 5: Commit**

```bash
git add supabase/config.toml tests/db/test_00_preflight.sh scripts/db/preflight.sh
git commit -m "chore(db): bootstrap supabase workspace and preflight checks"
```

### Task 2: Create Schema Freeze Specification (Single Source of Truth)

**Files:**
- Create: `docs/governance/SCHEMA-FREEZE-2026-02-23.md`
- Create: `tests/db/test_01_schema_freeze.sh`
- Test: `tests/db/test_01_schema_freeze.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

f="docs/governance/SCHEMA-FREEZE-2026-02-23.md"
test -f "$f"
grep -q "Total Tables: 31" "$f"
grep -q "notifications: from_user_id,to_user_id" "$f"
grep -q "Transactional Outbox: required" "$f"
grep -q "request_id idempotency: required" "$f"
echo "schema freeze ready"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_01_schema_freeze.sh`  
Expected: FAIL because freeze file does not exist yet.

**Step 3: Write minimal implementation**

```markdown
# SCHEMA FREEZE (2026-02-23)

- Total Tables: 31
- notifications: from_user_id,to_user_id
- Transactional Outbox: required
- request_id idempotency: required
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_01_schema_freeze.sh`  
Expected: PASS with `schema freeze ready`.

**Step 5: Commit**

```bash
git add docs/governance/SCHEMA-FREEZE-2026-02-23.md tests/db/test_01_schema_freeze.sh
git commit -m "docs(db): add schema freeze specification"
```

### Task 3: Add Destructive Full-Rebuild Migration Skeleton

**Files:**
- Create: `supabase/migrations/20260223170000_rebuild_all.sql`
- Create: `tests/db/test_02_migration_skeleton.sh`
- Test: `tests/db/test_02_migration_skeleton.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

f="supabase/migrations/20260223170000_rebuild_all.sql"
test -f "$f"
grep -q "drop table if exists public.chat_messages" "$f"
grep -q "create table public.conversations" "$f"
grep -q "create table public.chat_messages" "$f"
grep -q "create table public.operation_logs" "$f"
grep -q "create table public.snapshot_refresh_events" "$f"
echo "migration skeleton ready"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_02_migration_skeleton.sh`  
Expected: FAIL because migration file does not exist.

**Step 3: Write minimal implementation**

```sql
-- destructive rebuild
drop table if exists public.chat_messages cascade;
drop table if exists public.conversations cascade;
drop table if exists public.operation_logs cascade;
drop table if exists public.snapshot_refresh_events cascade;

create table public.conversations (...);
create table public.chat_messages (...);
create table public.operation_logs (...);
create table public.snapshot_refresh_events (...);
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_02_migration_skeleton.sh`  
Expected: PASS with `migration skeleton ready`.

**Step 5: Commit**

```bash
git add supabase/migrations/20260223170000_rebuild_all.sql tests/db/test_02_migration_skeleton.sh
git commit -m "feat(db): add destructive rebuild migration skeleton"
```

### Task 4: Complete 31-Table DDL + Constraints + Indexes

**Files:**
- Modify: `supabase/migrations/20260223170000_rebuild_all.sql`
- Create: `tests/db/test_03_schema_counts.sh`
- Test: `tests/db/test_03_schema_counts.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
grep -q "create table public.admin_users" /tmp/starpath_schema.sql
grep -q "create table public.push_tasks" /tmp/starpath_schema.sql
grep -q "create table public.child_snapshots" /tmp/starpath_schema.sql
echo "full table set exists in dump"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_03_schema_counts.sh`  
Expected: FAIL because full DDL is incomplete.

**Step 3: Write minimal implementation**

```sql
-- Add remaining 31-table definitions
-- Add primary keys, foreign keys, unique constraints
-- Add indexes from 04 design doc
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_03_schema_counts.sh`  
Expected: PASS with `full table set exists in dump`.

**Step 5: Commit**

```bash
git add supabase/migrations/20260223170000_rebuild_all.sql tests/db/test_03_schema_counts.sh scripts/db/dump_schema.sh
git commit -m "feat(db): complete full schema ddl constraints and indexes"
```

### Task 5: Add RLS Policies and Security Helpers

**Files:**
- Modify: `supabase/migrations/20260223170000_rebuild_all.sql`
- Create: `tests/db/test_04_rls_presence.sh`
- Test: `tests/db/test_04_rls_presence.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
grep -q "alter table public.chat_messages enable row level security" /tmp/starpath_schema.sql
grep -q "create policy" /tmp/starpath_schema.sql
grep -q "to_user_id" /tmp/starpath_schema.sql
echo "rls policy baseline exists"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_04_rls_presence.sh`  
Expected: FAIL because RLS/policies are not complete yet.

**Step 3: Write minimal implementation**

```sql
alter table public.chat_messages enable row level security;
alter table public.conversations enable row level security;
-- add parent/doctor/teacher/org_admin/admin policy blocks
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_04_rls_presence.sh`  
Expected: PASS with `rls policy baseline exists`.

**Step 5: Commit**

```bash
git add supabase/migrations/20260223170000_rebuild_all.sql tests/db/test_04_rls_presence.sh
git commit -m "feat(db): add rls policies and security baseline"
```

### Task 6: Add Trigger and RPC for Transactional Outbox + Conversation Sync

**Files:**
- Modify: `supabase/migrations/20260223170000_rebuild_all.sql`
- Create: `tests/db/test_05_outbox_and_triggers.sh`
- Test: `tests/db/test_05_outbox_and_triggers.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
grep -q "create function public.finalize_writeback" /tmp/starpath_schema.sql
grep -q "create trigger trg_chat_message_update_conversation" /tmp/starpath_schema.sql
echo "outbox rpc and trigger present"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_05_outbox_and_triggers.sh`  
Expected: FAIL because RPC/trigger are missing.

**Step 3: Write minimal implementation**

```sql
create function public.finalize_writeback(...) returns void as $$
begin
  -- insert snapshot_refresh_events
  -- insert operation_logs
end;
$$ language plpgsql security definer;

create trigger trg_chat_message_update_conversation
after insert on public.chat_messages
for each row execute function public.sync_conversation_after_message();
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_05_outbox_and_triggers.sh`  
Expected: PASS with `outbox rpc and trigger present`.

**Step 5: Commit**

```bash
git add supabase/migrations/20260223170000_rebuild_all.sql tests/db/test_05_outbox_and_triggers.sh
git commit -m "feat(db): add transactional outbox rpc and conversation sync trigger"
```

### Task 7: Apply Rebuild Migration to Linked Supabase

**Files:**
- Create: `scripts/db/rebuild_remote.sh`
- Create: `tests/db/test_06_apply_rebuild.sh`
- Test: `tests/db/test_06_apply_rebuild.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/rebuild_remote.sh
echo "remote rebuild done"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/db/test_06_apply_rebuild.sh`  
Expected: FAIL before script is implemented.

**Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

supabase db push --linked --include-all
supabase db dump --linked --schema public -f /tmp/starpath_schema.sql
```

**Step 4: Run test to verify it passes**

Run: `bash tests/db/test_06_apply_rebuild.sh`  
Expected: PASS with `remote rebuild done`.

**Step 5: Commit**

```bash
git add scripts/db/rebuild_remote.sh tests/db/test_06_apply_rebuild.sh
git commit -m "chore(db): apply destructive rebuild migration to linked project"
```

### Task 8: Implement Shared Edge Modules (`auth`, `model-router`, `finalize`, `sse`)

**Files:**
- Create: `supabase/functions/_shared/auth.ts`
- Create: `supabase/functions/_shared/model-router.ts`
- Create: `supabase/functions/_shared/finalize.ts`
- Create: `supabase/functions/_shared/sse.ts`
- Create: `tests/functions/test_shared_modules.sh`
- Test: `tests/functions/test_shared_modules.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/_shared/auth.ts
test -f supabase/functions/_shared/model-router.ts
test -f supabase/functions/_shared/finalize.ts
test -f supabase/functions/_shared/sse.ts
echo "shared modules exist"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/functions/test_shared_modules.sh`  
Expected: FAIL because files do not exist.

**Step 3: Write minimal implementation**

```ts
// auth.ts
export async function authenticate(req: Request) { /* verify JWT */ }

// model-router.ts
export async function callModelLive(input: string) { /* doubao/kimi */ }

// finalize.ts
export async function finalizeWriteback(...) { /* rpc finalize_writeback */ }

// sse.ts
export function sseEvent(type: string, data: unknown): string { /* format event */ }
```

**Step 4: Run test to verify it passes**

Run: `bash tests/functions/test_shared_modules.sh`  
Expected: PASS with `shared modules exist`.

**Step 5: Commit**

```bash
git add supabase/functions/_shared tests/functions/test_shared_modules.sh
git commit -m "feat(functions): add shared auth model finalize and sse modules"
```

### Task 9: Implement `orchestrator` and `chat-casual` Live Chain

**Files:**
- Create: `supabase/functions/orchestrator/index.ts`
- Create: `supabase/functions/chat-casual/index.ts`
- Create: `tests/functions/test_chain_files.sh`
- Test: `tests/functions/test_chain_files.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/orchestrator/index.ts
test -f supabase/functions/chat-casual/index.ts
grep -q "request_id" supabase/functions/orchestrator/index.ts
grep -q "finalizeWriteback" supabase/functions/chat-casual/index.ts
echo "chain files and key hooks present"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/functions/test_chain_files.sh`  
Expected: FAIL because functions are not implemented.

**Step 3: Write minimal implementation**

```ts
// orchestrator/index.ts
// 1) auth 2) conversation upsert 3) user message insert 4) route to chat-casual

// chat-casual/index.ts
// 1) auth + permission 2) model call 3) assistant insert 4) finalize writeback 5) SSE done/error
```

**Step 4: Run test to verify it passes**

Run: `bash tests/functions/test_chain_files.sh`  
Expected: PASS with `chain files and key hooks present`.

**Step 5: Commit**

```bash
git add supabase/functions/orchestrator/index.ts supabase/functions/chat-casual/index.ts tests/functions/test_chain_files.sh
git commit -m "feat(functions): implement orchestrator to chat-casual live chain"
```

### Task 10: Add Live Smoke Test and Verification Report

**Files:**
- Create: `tests/e2e/test_orchestrator_chat_casual_live.sh`
- Create: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
- Test: `tests/e2e/test_orchestrator_chat_casual_live.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Expect script to call orchestrator endpoint and assert DB side effects:
# - user message inserted
# - assistant message inserted
# - operation_logs row exists
# - snapshot_refresh_events row exists
exit 1
```

**Step 2: Run test to verify it fails**

Run: `bash tests/e2e/test_orchestrator_chat_casual_live.sh`  
Expected: FAIL by design.

**Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1) get jwt
# 2) call orchestrator edge endpoint with request_id
# 3) query Supabase REST with service role for assertions
# 4) fail on any missing side effect
```

**Step 4: Run test to verify it passes**

Run: `bash tests/e2e/test_orchestrator_chat_casual_live.sh`  
Expected: PASS and print smoke verification summary.

**Step 5: Commit**

```bash
git add tests/e2e/test_orchestrator_chat_casual_live.sh docs/governance/REBUILD-VERIFICATION-2026-02-23.md docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): verify live orchestrator to chat-casual chain with writeback evidence"
```

### Task 11: Enforce CI Gate for DB Rebuild and Chain Smoke

**Files:**
- Modify: `.github/workflows/contract-governance-check.yml`
- Create: `.github/workflows/db-rebuild-and-chain-smoke.yml`
- Create: `tests/ci/test_workflow_presence.sh`
- Test: `tests/ci/test_workflow_presence.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

test -f .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "supabase db push" .github/workflows/db-rebuild-and-chain-smoke.yml
grep -q "test_orchestrator_chat_casual_live.sh" .github/workflows/db-rebuild-and-chain-smoke.yml
echo "db and chain ci gate present"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/ci/test_workflow_presence.sh`  
Expected: FAIL because workflow is not present.

**Step 3: Write minimal implementation**

```yaml
name: db-rebuild-and-chain-smoke
on:
  pull_request:
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/db/rebuild_remote.sh
      - run: bash tests/e2e/test_orchestrator_chat_casual_live.sh
```

**Step 4: Run test to verify it passes**

Run: `bash tests/ci/test_workflow_presence.sh`  
Expected: PASS with `db and chain ci gate present`.

**Step 5: Commit**

```bash
git add .github/workflows/db-rebuild-and-chain-smoke.yml tests/ci/test_workflow_presence.sh
git commit -m "ci(db): add rebuild and live chain smoke gate"
```

### Task 12: Final Verification Sweep

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Test: `tests/db/*.sh`, `tests/functions/*.sh`, `tests/e2e/*.sh`, `tests/ci/*.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "placeholder fail" >&2
exit 1
```

**Step 2: Run test to verify it fails**

Run: `bash /tmp/final_gate.sh`  
Expected: FAIL by design.

**Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

bash governance/agent-contract/scripts/build-contract.sh
bash governance/agent-contract/scripts/verify-contract.sh
for t in tests/db/*.sh tests/functions/*.sh tests/e2e/*.sh tests/ci/*.sh; do
  bash "$t"
done
```

**Step 4: Run test to verify it passes**

Run: `bash /tmp/final_gate.sh`  
Expected: PASS and produce fresh verification timestamp.

**Step 5: Commit**

```bash
git add docs/governance/REBUILD-VERIFICATION-2026-02-23.md
git commit -m "chore(verification): finalize db rebuild and execution chain evidence"
```

## Execution Notes

- Always run `@test-driven-development` and keep red-green-refactor discipline per task.
- Do not execute destructive rebuild without preflight backup evidence captured in docs.
- Treat `.env` values as secrets; never print key values in logs or reports.
- If `supabase db push --linked` fails, stop and repair migration, do not patch production manually.

Plan complete and saved to `docs/plans/2026-02-23-execution-chain-rebuild.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
