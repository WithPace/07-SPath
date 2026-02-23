#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
bash governance/agent-contract/scripts/verify-contract.sh
test -f docs/governance/BASELINE-VERIFICATION-2026-02-23.md
echo "e2e governance baseline complete"
