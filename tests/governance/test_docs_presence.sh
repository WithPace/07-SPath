#!/usr/bin/env bash
set -euo pipefail
test -f docs/governance/GOVERNANCE-README.md
test -f docs/governance/GAP-REGISTER.md
grep -q "| id | category | description |" docs/governance/GAP-REGISTER.md
echo "governance docs ready"
