# Governance README

This repository uses governance-first agent execution with one source contract:

- Source of truth: `governance/agent-contract/source/contract.yaml`
- Generated outputs:
  - `AGENTS.md`
  - `CLAUDE.md`
  - `.cursor/rules/starpath-contract.mdc`
- Verification gates:
  - `governance/agent-contract/scripts/build-contract.sh`
  - `governance/agent-contract/scripts/verify-contract.sh`

## Operating Rules

1. Edit only `contract.yaml` for rule changes.
2. Regenerate outputs after each change.
3. Do not manually edit generated target files.
4. Open gaps in `docs/governance/GAP-REGISTER.md`.
5. Attach verification evidence before claiming completion.
