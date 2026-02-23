# SCHEMA FREEZE (2026-02-23)

## Scope

- Source docs: `docs/01-PRD-产品需求文档.md`, `docs/04-数据结构化设计文档.md`
- Rebuild mode: destructive drop + recreate via Supabase CLI
- Target: full schema freeze before migrations

## Core Freeze Markers

- Total Tables: 31
- notifications: from_user_id,to_user_id
- Transactional Outbox: required
- request_id idempotency: required

## Domain Count

- Business tables: 17
- Conversation tables: 2
- Admin tables: 9
- System runtime tables: 3

## P0 Decisions

1. Freeze exact DDL for 31 tables before SQL generation.
2. Backup schema/data before destructive push.
3. Enforce same-transaction writeback for business write + outbox + operation log.
4. Enforce auth baseline for all function entry points.
5. Block ambiguous notification fields (`user_id`, `from_role`).
6. Enforce request-level idempotency key handling.
7. Keep conversation header and message body consistency via trigger/RPC.

## P1 Decisions

1. Add PII minimization policy for live model payloads.
2. Add SQL-level RLS acceptance tests for all roles.
3. Add CI gate for schema/RLS/chain smoke checks.

## Open Risks

- Document drift across design docs can reintroduce schema mismatch.
- Live model chain may expose sensitive fields without payload filtering.
- Destructive rebuild requires verified backup and restore path.
