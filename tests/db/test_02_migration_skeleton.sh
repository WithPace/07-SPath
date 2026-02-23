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
