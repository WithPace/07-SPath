# Orchestrator Conversation Bootstrap Contract Design

## Context

- `orchestrator` is the execution-chain ingress and is responsible for conversation continuity.
- Current contracts protect route tuples, forwarding semantics, auth/body parse, and error responses.
- Conversation bootstrap and user-message writeback assumptions are critical but not isolated as a dedicated gate.

## Problem

- A refactor can break auto-conversation creation when `conversation_id` is missing.
- A refactor can omit required conversation defaults (`last_message_at`, `message_count`, `is_deleted`).
- A refactor can break insertion of the incoming user message into `chat_messages` before forwarding.

## Options

### Option A: Depend on live smokes only

Trade-offs:
- Pros: no new test file.
- Cons: delayed detection and harder localization when regression occurs.

### Option B (Selected): Add static conversation bootstrap contract gate

- Add one static test that enforces:
  - conditional conversation bootstrap branch (`if (!conversationId)`).
  - canonical `conversations` insert fields.
  - canonical `chat_messages` user write fields in orchestrator.
  - failure throws on conversation/user-message write errors.

Trade-offs:
- Pros: fast deterministic governance guard for ingress persistence invariants.
- Cons: tied to current implementation style.

### Option C: Add mocked runtime integration for conversation bootstrap

Trade-offs:
- Pros: richer behavior assurance.
- Cons: heavier harness and maintenance cost.

## Chosen Design

- Implement Option B via:
  - `tests/functions/test_orchestrator_conversation_bootstrap_contract.sh`
- Keep scope additive with no production behavior changes.
- Integrate into `final_gate` through existing `tests/functions/*.sh` sweep.
