#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

dashboard="supabase/functions/dashboard/index.ts"
orchestrator="supabase/functions/orchestrator/index.ts"
shared_auth="supabase/functions/_shared/auth.ts"

test -f "$dashboard" || fail "missing dashboard function file"
test -f "$orchestrator" || fail "missing orchestrator function file"
test -f "$shared_auth" || fail "missing shared auth file"

rg -q 'export type ChildRole' "$shared_auth" || fail "missing ChildRole type in shared auth"
rg -q 'normalizeChildRole' "$shared_auth" || fail "missing role normalization helper in shared auth"
rg -q 'checkChildRoleAccess' "$shared_auth" || fail "missing role-scoped access helper in shared auth"

for role in parent doctor teacher org_admin; do
  rg -q "\\b${role}\\b" "$dashboard" || fail "dashboard missing role matrix branch: ${role}"
done

if rg -q 'dashboard currently supports role=parent only' "$dashboard"; then
  fail "dashboard still hardcoded to parent-only"
fi

rg -q 'checkChildRoleAccess\(user\.id, payload\.child_id, role\)' "$dashboard" \
  || fail "dashboard missing role-scoped access check"
rg -q 'payload: \{' "$dashboard" || fail "dashboard missing finalize payload block"
rg -q 'role,' "$dashboard" || fail "dashboard done/finalize payload missing dynamic role field"

rg -q 'role\?: string;' "$orchestrator" || fail "orchestrator payload missing role field"
rg -q 'normalizeChildRole' "$orchestrator" || fail "orchestrator missing role normalization"
rg -q 'checkChildRoleAccess\(user\.id, payload\.child_id, role\)' "$orchestrator" \
  || fail "orchestrator missing role-scoped access check"
rg -q 'request_id: requestId,' "$orchestrator" || fail "orchestrator forward body missing request_id"
rg -q 'role,' "$orchestrator" || fail "orchestrator forward body missing role field"

echo "phase5 dashboard role matrix contract present"
