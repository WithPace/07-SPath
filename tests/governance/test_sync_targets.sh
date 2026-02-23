#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
cmp -s AGENTS.md governance/agent-contract/generated/AGENTS.generated.md
cmp -s CLAUDE.md governance/agent-contract/generated/CLAUDE.generated.md
cmp -s .cursor/rules/starpath-contract.mdc governance/agent-contract/generated/cursor.generated.mdc
echo "targets synced"
