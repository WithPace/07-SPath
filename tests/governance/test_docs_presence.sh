#!/usr/bin/env bash
set -euo pipefail
test -f docs/governance/GOVERNANCE-README.md
test -f docs/governance/GAP-REGISTER.md
test -f docs/governance/PHASE-2-CONTRACT-CATALOG.md
test -f docs/governance/PHASE-2-RELEASE-CHECKLIST.md
test -f docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md
grep -q "| id | category | description |" docs/governance/GAP-REGISTER.md
echo "governance docs ready"
