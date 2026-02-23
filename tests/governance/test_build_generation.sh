#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
test -f governance/agent-contract/generated/AGENTS.generated.md
test -f governance/agent-contract/generated/CLAUDE.generated.md
test -f governance/agent-contract/generated/cursor.generated.mdc
echo "build outputs generated"
