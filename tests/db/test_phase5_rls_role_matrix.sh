#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

migration="supabase/migrations/20260223170000_rebuild_all.sql"
shared_auth="supabase/functions/_shared/auth.ts"

test -f "$migration" || fail "missing rebuild migration"
test -f "$shared_auth" || fail "missing shared auth helper"

rg -q 'create table public\.care_teams' "$migration" || fail "missing care_teams table in rebuild migration"
rg -q 'role varchar not null' "$migration" || fail "care_teams role column missing in rebuild migration"
rg -q 'unique \(user_id, child_id, role\)' "$migration" || fail "care_teams unique role matrix key missing"

rg -q 'create or replace function public\.has_child_access' "$migration" \
  || fail "missing has_child_access helper in rebuild migration"
rg -q "ct\.status = 'active'" "$migration" || fail "has_child_access must enforce active care_team status"

for policy in children_team_read assessments_access training_plans_access training_sessions_access; do
  rg -q "create policy ${policy}" "$migration" || fail "missing policy ${policy} in rebuild migration"
done

rg -q 'public\.has_child_access\(child_id\)' "$migration" \
  || fail "rebuild migration missing has_child_access policy bindings"

rg -q 'export type ChildRole' "$shared_auth" || fail "missing ChildRole type in shared auth"
rg -q 'checkChildRoleAccess' "$shared_auth" || fail "missing role-scoped access helper"
for role in parent doctor teacher org_admin; do
  rg -q "\\b${role}\\b" "$shared_auth" || fail "shared auth missing role ${role}"
done

echo "phase5 rls role matrix contract present"
