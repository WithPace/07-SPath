#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
grep -q "Module Contracts (3)" governance/agent-contract/generated/AGENTS.generated.md
grep -q '`orchestrator`' governance/agent-contract/generated/AGENTS.generated.md
grep -q '`assessment`' governance/agent-contract/generated/AGENTS.generated.md
grep -q '`training`' governance/agent-contract/generated/AGENTS.generated.md
echo "build includes modules"
