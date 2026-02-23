#!/usr/bin/env bash
set -euo pipefail

f="docs/governance/SCHEMA-FREEZE-2026-02-23.md"
test -f "$f"
grep -q "Total Tables: 31" "$f"
grep -q "notifications: from_user_id,to_user_id" "$f"
grep -q "Transactional Outbox: required" "$f"
grep -q "request_id idempotency: required" "$f"
echo "schema freeze ready"
