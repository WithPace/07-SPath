# StarPath Harness Governance (Agent Contract as Code) Design

**Date:** 2026-02-23  
**Status:** Approved

## 1. Background and Goal

This repository is currently documentation-first (no runnable backend code yet).  
To enable AI-assisted delivery with control and consistency, we adopt a governance-first approach:

- Priority: constraint layer first
- Scope: multi-agent unified protocol (Codex / Claude / Cursor)
- Method: Agent Contract as Code (single source -> generated agent rules)

Primary goal:
- Ensure all agent behavior is governed by one auditable contract, with CI verification and drift blocking.

## 2. Chosen Approach

Selected option: **Scheme B - Agent Contract as Code**.

Why:
- One source of truth for all agents
- Generated targets avoid manual drift
- Compatible with Harness Engineering style verification loops
- Supports audit / optimize / fill-gap as mandatory tracks

## 3. Governance Architecture

### 3.1 Single Source of Truth

- Human-editable source: `governance/agent-contract/source/contract.yaml`
- Generated artifacts:
  - `AGENTS.md` (Codex)
  - `CLAUDE.md` (Claude)
  - `.cursor/rules/starpath-contract.mdc` (Cursor)
- Lock file:
  - `governance/agent-contract/contract.lock.json`

### 3.2 Precedence

Rules follow explicit priority:
1. Global
2. Repository
3. Module-level

Lower levels may override only when explicitly declared and traceable.

### 3.3 Governance Triad for Every Change

Every change runs three tracks:
- `audit`: review current state
- `optimize`: improve structure/rules
- `fill-gap`: register and close missing items

## 4. Planned Directory Skeleton

```text
governance/
  agent-contract/
    source/
      contract.yaml
    schema/
      contract.schema.json
    mapping/
      codex.map.yaml
      claude.map.yaml
      cursor.map.yaml
    templates/
      agents.md.tmpl
      claude.md.tmpl
      cursor-rule.tmpl
    generated/
      AGENTS.generated.md
      CLAUDE.generated.md
      cursor.generated.mdc
    checks/
      required-clauses.yaml
      risk-catalog.yaml
    scripts/
      build-contract.sh
      verify-contract.sh
    contract.lock.json
docs/
  governance/
    GOVERNANCE-README.md
    GAP-REGISTER.md
    DECISIONS/
      0001-agent-contract.md
```

## 5. Contract Model (Minimum Viable Fields)

`contract.yaml` should include:

- `meta` (project, owners, applies_to)
- `principles` (including `evidence_before_claim`)
- `roles` (planner, implementer, reviewer)
- `constraints` (non-interactive, forbidden commands, destructive approval)
- `workflow` (must include `audit`, `optimize`, `fill_gap`)
- `quality_gates` (blocking checks)
- `gap_management` (register, labels, SLA)
- `mapping` (Codex/Claude/Cursor target paths)

Mandatory non-removable controls for phase 1:
1. `evidence_before_claim`
2. forbidden destructive commands baseline
3. workflow includes `audit/optimize/fill_gap`
4. blocking gate on check failure
5. unified gap register path

## 6. Build and Verify Flow

### 6.1 Local

1. Edit source contract
2. Run build script
3. Generate target artifacts and lock
4. Run verify script
5. Sync generated outputs to root target files

### 6.2 CI

PR workflow `contract-governance-check`:
1. Rebuild
2. Re-verify
3. Block merge on any mismatch/failure
4. Emit audit metadata (version/hash/gap stats)

### 6.3 Failure Handling

- Schema failure: block immediately
- Missing required clauses: block immediately
- Drift (manual edits in generated targets): block until source-based regeneration

## 7. Risk, Rollback, and Gap Closure

### 7.1 Risk Levels

- `P0`: security/destructive risk -> immediate block and explicit approval
- `P1`: consistency/drift risk -> CI block and short SLA fix
- `P2`: completeness/documentation risk -> tracked and closed before stage advance

### 7.2 Rollback

- Rollback anchor: prior `contract.lock.json`
- Regenerate from previous lock-compatible source
- Re-run verify before restore completion
- Record rollback decision in `docs/governance/DECISIONS/`

### 7.3 Gap Register

`docs/governance/GAP-REGISTER.md` fields:
- id
- category (`missing` / `conflict` / `risk` / `debt`)
- description
- impact
- owner
- due_date
- status
- evidence

## 8. Phase 1 Deliverables and Acceptance

### 8.1 Deliverables

1. Contract source + schema + mapping
2. Generated Codex/Claude/Cursor rule files + lock
3. Build/verify scripts
4. Governance docs + ADR + gap register
5. CI blocking workflow

### 8.2 Acceptance Criteria

1. One-command generation works and updates lock hash
2. CI detects and blocks generated-target manual edits
3. Mandatory clauses are enforced
4. Gap register is active and traceable by owner/SLA
5. Rollback works from lock baseline and passes verification

## 9. Current Constraints and Notes

- This workspace is not a Git repository root at current path, so commit operations cannot be executed here yet.
- Implementation phase should begin by creating governance scaffolding files and CI workflow before business module work.

## 10. References

- OpenAI: Introducing harness engineering  
  https://openai.com/index/introducing-harness-engineering/
- OpenAI: Unlocking the Codex harness app server  
  https://openai.com/index/unlocking-the-codex-harness-app-server/
- OpenAI Codex documentation root  
  https://developers.openai.com/codex
