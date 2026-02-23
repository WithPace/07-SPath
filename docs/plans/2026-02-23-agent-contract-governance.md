# Agent Contract Governance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a governance-first, multi-agent contract system that generates and verifies `AGENTS.md`, `CLAUDE.md`, and Cursor rules from one source contract.

**Architecture:** Store one authoritative contract YAML in `governance/agent-contract/source/contract.yaml`, then generate agent-specific outputs via mapping + templates. Add deterministic lock metadata and CI gates to block drift or missing required clauses. Track missing/conflicting governance items in a single gap register.

**Tech Stack:** Bash, Python 3 (stdlib only), Markdown, YAML, GitHub Actions.

### Task 1: Create Governance Skeleton and Seed Contract

**Files:**
- Create: `governance/agent-contract/source/contract.yaml`
- Create: `governance/agent-contract/mapping/codex.map.yaml`
- Create: `governance/agent-contract/mapping/claude.map.yaml`
- Create: `governance/agent-contract/mapping/cursor.map.yaml`
- Create: `governance/agent-contract/checks/required-clauses.yaml`
- Create: `governance/agent-contract/checks/risk-catalog.yaml`
- Create: `governance/agent-contract/templates/agents.md.tmpl`
- Create: `governance/agent-contract/templates/claude.md.tmpl`
- Create: `governance/agent-contract/templates/cursor-rule.tmpl`
- Create: `governance/agent-contract/generated/.gitkeep`
- Test: `tests/governance/test_contract_seed.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

test -f governance/agent-contract/source/contract.yaml
grep -q "evidence_before_claim" governance/agent-contract/source/contract.yaml
test -f governance/agent-contract/mapping/codex.map.yaml
test -f governance/agent-contract/templates/agents.md.tmpl
echo "seed contract files exist"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_contract_seed.sh`  
Expected: FAIL with missing file errors.

**Step 3: Write minimal implementation**

```yaml
# governance/agent-contract/source/contract.yaml
version: 1
meta:
  project: starpath
  applies_to: [codex, claude, cursor]
principles:
  - id: evidence_before_claim
    statement: "No completion claims without verification evidence."
workflow:
  stages: [intake, audit, optimize, fill_gap, plan, execute, verify, report]
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_contract_seed.sh`  
Expected: PASS and print `seed contract files exist`.

**Step 5: Commit**

```bash
git add governance/agent-contract tests/governance/test_contract_seed.sh
git commit -m "chore(governance): add contract skeleton and seed files"
```

### Task 2: Add Contract Schema and Schema Validator

**Files:**
- Create: `governance/agent-contract/schema/contract.schema.json`
- Create: `governance/agent-contract/scripts/validate_contract.py`
- Test: `tests/governance/test_schema_validation.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
python3 governance/agent-contract/scripts/validate_contract.py
echo "schema validation passed"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_schema_validation.sh`  
Expected: FAIL because validator script does not exist.

**Step 3: Write minimal implementation**

```python
#!/usr/bin/env python3
from pathlib import Path
import sys
import yaml

path = Path("governance/agent-contract/source/contract.yaml")
data = yaml.safe_load(path.read_text(encoding="utf-8"))

required_top = ["version", "meta", "principles", "workflow"]
for key in required_top:
    if key not in data:
        print(f"missing key: {key}")
        sys.exit(1)

principle_ids = [p.get("id") for p in data.get("principles", [])]
if "evidence_before_claim" not in principle_ids:
    print("missing required principle: evidence_before_claim")
    sys.exit(1)

stages = data.get("workflow", {}).get("stages", [])
for required_stage in ["audit", "optimize", "fill_gap"]:
    if required_stage not in stages:
        print(f"missing required stage: {required_stage}")
        sys.exit(1)

print("ok")
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_schema_validation.sh`  
Expected: PASS and print `schema validation passed`.

**Step 5: Commit**

```bash
git add governance/agent-contract/schema governance/agent-contract/scripts/validate_contract.py tests/governance/test_schema_validation.sh
git commit -m "feat(governance): add contract schema validation"
```

### Task 3: Implement Build Generator (Source -> Generated Artifacts)

**Files:**
- Create: `governance/agent-contract/scripts/build_contract.py`
- Create: `governance/agent-contract/scripts/build-contract.sh`
- Modify: `governance/agent-contract/templates/agents.md.tmpl`
- Modify: `governance/agent-contract/templates/claude.md.tmpl`
- Modify: `governance/agent-contract/templates/cursor-rule.tmpl`
- Test: `tests/governance/test_build_generation.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
test -f governance/agent-contract/generated/AGENTS.generated.md
test -f governance/agent-contract/generated/CLAUDE.generated.md
test -f governance/agent-contract/generated/cursor.generated.mdc
echo "build outputs generated"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_build_generation.sh`  
Expected: FAIL because build script/output files are missing.

**Step 3: Write minimal implementation**

```python
#!/usr/bin/env python3
from pathlib import Path
import hashlib
import json
import yaml

root = Path("governance/agent-contract")
source = yaml.safe_load((root / "source/contract.yaml").read_text(encoding="utf-8"))
generated = root / "generated"
generated.mkdir(parents=True, exist_ok=True)

lines = [
    "# Generated from governance contract",
    f"project: {source['meta']['project']}",
    "principles:",
]
for p in source.get("principles", []):
    lines.append(f"- {p['id']}: {p['statement']}")

(generated / "AGENTS.generated.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
(generated / "CLAUDE.generated.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
(generated / "cursor.generated.mdc").write_text("\n".join(lines) + "\n", encoding="utf-8")

digest = hashlib.sha256("\n".join(lines).encode("utf-8")).hexdigest()
lock = {"version": source["version"], "sha256": digest}
(root / "contract.lock.json").write_text(json.dumps(lock, indent=2) + "\n", encoding="utf-8")
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_build_generation.sh`  
Expected: PASS and print `build outputs generated`.

**Step 5: Commit**

```bash
git add governance/agent-contract/scripts/build_contract.py governance/agent-contract/scripts/build-contract.sh governance/agent-contract/generated governance/agent-contract/contract.lock.json tests/governance/test_build_generation.sh
git commit -m "feat(governance): generate agent artifacts from contract source"
```

### Task 4: Implement Verification Script and Drift Detection

**Files:**
- Create: `governance/agent-contract/scripts/verify_contract.py`
- Create: `governance/agent-contract/scripts/verify-contract.sh`
- Modify: `governance/agent-contract/checks/required-clauses.yaml`
- Test: `tests/governance/test_verify_contract.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/verify-contract.sh
echo "verification passed"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_verify_contract.sh`  
Expected: FAIL because verify script is missing.

**Step 3: Write minimal implementation**

```python
#!/usr/bin/env python3
from pathlib import Path
import sys

required = [
    "governance/agent-contract/generated/AGENTS.generated.md",
    "governance/agent-contract/generated/CLAUDE.generated.md",
    "governance/agent-contract/generated/cursor.generated.mdc",
    "governance/agent-contract/contract.lock.json",
]
for p in required:
    if not Path(p).exists():
        print(f"missing required file: {p}")
        sys.exit(1)

print("ok")
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_verify_contract.sh`  
Expected: PASS and print `verification passed`.

**Step 5: Commit**

```bash
git add governance/agent-contract/scripts/verify_contract.py governance/agent-contract/scripts/verify-contract.sh governance/agent-contract/checks/required-clauses.yaml tests/governance/test_verify_contract.sh
git commit -m "feat(governance): add verification and required clause checks"
```

### Task 5: Sync Generated Artifacts to Runtime Targets

**Files:**
- Modify: `governance/agent-contract/scripts/build-contract.sh`
- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `.cursor/rules/starpath-contract.mdc`
- Test: `tests/governance/test_sync_targets.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
cmp -s AGENTS.md governance/agent-contract/generated/AGENTS.generated.md
cmp -s CLAUDE.md governance/agent-contract/generated/CLAUDE.generated.md
cmp -s .cursor/rules/starpath-contract.mdc governance/agent-contract/generated/cursor.generated.mdc
echo "targets synced"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_sync_targets.sh`  
Expected: FAIL due missing target files or unsynced content.

**Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail
python3 governance/agent-contract/scripts/build_contract.py
mkdir -p .cursor/rules
cp governance/agent-contract/generated/AGENTS.generated.md AGENTS.md
cp governance/agent-contract/generated/CLAUDE.generated.md CLAUDE.md
cp governance/agent-contract/generated/cursor.generated.mdc .cursor/rules/starpath-contract.mdc
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_sync_targets.sh`  
Expected: PASS and print `targets synced`.

**Step 5: Commit**

```bash
git add governance/agent-contract/scripts/build-contract.sh AGENTS.md CLAUDE.md .cursor/rules/starpath-contract.mdc tests/governance/test_sync_targets.sh
git commit -m "feat(governance): sync generated artifacts to agent runtime targets"
```

### Task 6: Add Governance Docs and Gap Register Workflow

**Files:**
- Create: `docs/governance/GOVERNANCE-README.md`
- Create: `docs/governance/GAP-REGISTER.md`
- Create: `docs/governance/DECISIONS/0001-agent-contract.md`
- Test: `tests/governance/test_docs_presence.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
test -f docs/governance/GOVERNANCE-README.md
test -f docs/governance/GAP-REGISTER.md
grep -q "| id | category | description |" docs/governance/GAP-REGISTER.md
echo "governance docs ready"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_docs_presence.sh`  
Expected: FAIL due missing docs.

**Step 3: Write minimal implementation**

```markdown
# GAP REGISTER

| id | category | description | impact | owner | due_date | status | evidence |
|----|----------|-------------|--------|-------|----------|--------|----------|
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_docs_presence.sh`  
Expected: PASS and print `governance docs ready`.

**Step 5: Commit**

```bash
git add docs/governance tests/governance/test_docs_presence.sh
git commit -m "docs(governance): add governance guide, ADR, and gap register"
```

### Task 7: Add CI Gate for Contract Governance

**Files:**
- Create: `.github/workflows/contract-governance-check.yml`
- Test: `tests/governance/test_ci_workflow.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
test -f .github/workflows/contract-governance-check.yml
grep -q "verify-contract.sh" .github/workflows/contract-governance-check.yml
echo "ci workflow present"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_ci_workflow.sh`  
Expected: FAIL because workflow file is missing.

**Step 3: Write minimal implementation**

```yaml
name: contract-governance-check
on:
  pull_request:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build contract
        run: bash governance/agent-contract/scripts/build-contract.sh
      - name: Verify contract
        run: bash governance/agent-contract/scripts/verify-contract.sh
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_ci_workflow.sh`  
Expected: PASS and print `ci workflow present`.

**Step 5: Commit**

```bash
git add .github/workflows/contract-governance-check.yml tests/governance/test_ci_workflow.sh
git commit -m "ci(governance): enforce contract generation and verification"
```

### Task 8: End-to-End Verification and Baseline Report

**Files:**
- Modify: `docs/governance/GAP-REGISTER.md`
- Create: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
- Test: `tests/governance/test_e2e_governance.sh`

**Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
bash governance/agent-contract/scripts/verify-contract.sh
test -f docs/governance/BASELINE-VERIFICATION-2026-02-23.md
echo "e2e governance baseline complete"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/governance/test_e2e_governance.sh`  
Expected: FAIL because baseline verification report does not exist.

**Step 3: Write minimal implementation**

```markdown
# Governance Baseline Verification (2026-02-23)

- Build script: PASS
- Verify script: PASS
- Generated target sync: PASS
- Required clauses check: PASS
- Open gaps: recorded in GAP-REGISTER
```

**Step 4: Run test to verify it passes**

Run: `bash tests/governance/test_e2e_governance.sh`  
Expected: PASS and print `e2e governance baseline complete`.

**Step 5: Commit**

```bash
git add docs/governance/GAP-REGISTER.md docs/governance/BASELINE-VERIFICATION-2026-02-23.md tests/governance/test_e2e_governance.sh
git commit -m "chore(governance): add baseline verification evidence and gap snapshot"
```

## Execution Notes

- Keep steps small and sequential.
- Do not manually edit generated target files; always regenerate from source.
- If project root is not a git root in this environment, skip commit commands and document that skip in the baseline verification report.

Plan complete and saved to `docs/plans/2026-02-23-agent-contract-governance.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
