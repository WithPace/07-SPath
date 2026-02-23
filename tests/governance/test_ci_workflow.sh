#!/usr/bin/env bash
set -euo pipefail
test -f .github/workflows/contract-governance-check.yml
grep -q "verify-contract.sh" .github/workflows/contract-governance-check.yml
echo "ci workflow present"
