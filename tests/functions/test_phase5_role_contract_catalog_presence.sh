#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

catalog="docs/governance/PHASE-5-ROLE-CONTRACT-CATALOG.md"
fixtures="docs/governance/PHASE-5-ROLE-CONTRACT-FIXTURES.md"

test -f "$catalog" || fail "missing phase5 role contract catalog"
test -f "$fixtures" || fail "missing phase5 role contract fixtures spec"

rg -q '^## Scope$' "$catalog" || fail "missing scope section in phase5 role contract catalog"
rg -q '^## Role Matrix$' "$catalog" || fail "missing role matrix section in phase5 role contract catalog"
rg -q '^## Module Contracts by Role$' "$catalog" || fail "missing module contracts by role section"
rg -q '^## Authorization and RLS Clauses$' "$catalog" || fail "missing authorization and rls clauses section"
rg -q '^## Verification Mapping$' "$catalog" || fail "missing verification mapping section"

for role in parent doctor teacher org_admin; do
  rg -q "\\b${role}\\b" "$catalog" || fail "missing role ${role} in catalog"
done

for module in chat-casual assessment training training-advice training-record dashboard orchestrator; do
  rg -q "\\b${module}\\b" "$catalog" || fail "missing module ${module} in catalog"
done

rg -q '^## Scope$' "$fixtures" || fail "missing scope section in phase5 role contract fixtures"
rg -q '^## Fixture Set$' "$fixtures" || fail "missing fixture set section in phase5 role contract fixtures"
rg -q '^## Validation Rules$' "$fixtures" || fail "missing validation rules section in phase5 role contract fixtures"
rg -q '^## Consumption in Frontend CI$' "$fixtures" || fail "missing frontend ci section in phase5 role contract fixtures"

rg -q 'parent.*done payload' "$fixtures" || fail "missing parent fixture requirement"
rg -q 'doctor.*done payload' "$fixtures" || fail "missing doctor fixture requirement"
rg -q 'teacher.*done payload' "$fixtures" || fail "missing teacher fixture requirement"
rg -q 'org_admin.*done payload' "$fixtures" || fail "missing org_admin fixture requirement"
rg -q 'admin web.*audit' "$fixtures" || fail "missing admin web audit fixture requirement"
rg -q 'retry.*transport_error' "$fixtures" || fail "missing retry transport error fixture requirement"

echo "phase5 role contract catalog and fixtures present"
