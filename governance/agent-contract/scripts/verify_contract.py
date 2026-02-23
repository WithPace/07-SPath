#!/usr/bin/env python3
from __future__ import annotations

from hashlib import sha256
from pathlib import Path
import json
import re
import sys


ROOT = Path("governance/agent-contract")
CONTRACT_PATH = ROOT / "source/contract.yaml"
MODULES_DIR = ROOT / "modules"
REQUIRED_CLAUSES_PATH = ROOT / "checks/required-clauses.yaml"
LOCK_PATH = ROOT / "contract.lock.json"
GENERATED_FILES = [
    ROOT / "generated/AGENTS.generated.md",
    ROOT / "generated/CLAUDE.generated.md",
    ROOT / "generated/cursor.generated.mdc",
]


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def parse_required_clauses(text: str) -> tuple[list[str], list[str], list[str]]:
    principles: list[str] = []
    workflow_stages: list[str] = []
    forbidden_commands: list[str] = []
    section: str | None = None
    in_forbidden = False

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        top = re.match(r"^([a-z_]+):\s*$", line)
        if top:
            section = top.group(1)
            in_forbidden = False
            continue

        if section == "constraints" and re.match(r"^\s*forbidden_commands:\s*$", line):
            in_forbidden = True
            continue

        item = re.match(r"^\s*-\s*(.+?)\s*$", line)
        if not item:
            continue
        value = item.group(1).strip().strip('"').strip("'")

        if section == "principles":
            principles.append(value)
        elif section == "workflow_stages":
            workflow_stages.append(value)
        elif section == "constraints" and in_forbidden:
            forbidden_commands.append(value)

    return principles, workflow_stages, forbidden_commands


def parse_required_modules(text: str) -> list[str]:
    required: list[str] = []
    in_modules = False
    in_required = False

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        if re.match(r"^modules:\s*$", line):
            in_modules = True
            in_required = False
            continue

        if in_modules and re.match(r"^[A-Za-z0-9_]+:\s*$", line):
            in_modules = False
            in_required = False

        if not in_modules:
            continue

        if re.match(r"^\s{2}required:\s*$", line):
            in_required = True
            continue

        if in_required:
            module_item = re.match(r"^\s{4}-\s*([A-Za-z0-9_-]+)\s*$", line)
            if module_item:
                required.append(module_item.group(1))
                continue
            if re.match(r"^\s{2}[A-Za-z0-9_]+:\s*$", line):
                in_required = False

    return required


def verify_required_clauses(contract_text: str, clauses_text: str) -> None:
    principles, stages, forbidden_commands = parse_required_clauses(clauses_text)

    for principle in principles:
        if re.search(rf"\bid:\s*{re.escape(principle)}\b", contract_text) is None:
            fail(f"missing required principle: {principle}")

    for stage in stages:
        if re.search(rf"^\s*-\s*{re.escape(stage)}\s*$", contract_text, flags=re.MULTILINE) is None:
            fail(f"missing required workflow stage: {stage}")

    for command in forbidden_commands:
        if command not in contract_text:
            fail(f"missing required forbidden command: {command}")


def verify_module_contracts(required_modules: list[str]) -> dict[str, str]:
    module_texts: dict[str, str] = {}
    for module_name in required_modules:
        path = MODULES_DIR / module_name / "contract.yaml"
        if not path.exists():
            fail(f"missing module contract: {path}")

        text = path.read_text(encoding="utf-8")
        module_texts[module_name] = text

        if re.search(rf"(?m)^module:\s*{re.escape(module_name)}\s*$", text) is None:
            fail(f"module declaration mismatch for {module_name}: {path}")

        for stage in ("audit", "optimize", "fill_gap"):
            if re.search(rf"(?m)^\s*-\s*{re.escape(stage)}\s*$", text) is None:
                fail(f"missing stage '{stage}' in module contract: {path}")

    return module_texts


def verify_lock(contract_text: str, required_modules: list[str], module_texts: dict[str, str]) -> None:
    if not LOCK_PATH.exists():
        fail(f"missing lock file: {LOCK_PATH}")

    lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    source_hash = sha256(contract_text.encode("utf-8")).hexdigest()
    if lock.get("source_sha256") != source_hash:
        fail("contract source hash mismatch; run build-contract.sh")

    if lock.get("required_modules") != sorted(required_modules):
        fail("required modules mismatch in lock; run build-contract.sh")

    module_source_hash = sha256(
        "".join(module_texts[name] for name in sorted(module_texts)).encode("utf-8")
    ).hexdigest()
    if lock.get("module_source_sha256") != module_source_hash:
        fail("module source hash mismatch; run build-contract.sh")

    combined_source_hash = sha256((contract_text + module_source_hash).encode("utf-8")).hexdigest()
    if lock.get("combined_source_sha256") != combined_source_hash:
        fail("combined source hash mismatch; run build-contract.sh")

    for file_path in GENERATED_FILES:
        if not file_path.exists():
            fail(f"missing generated file: {file_path}")

    generated_hash = sha256(
        "".join(file_path.read_text(encoding="utf-8") for file_path in sorted(GENERATED_FILES)).encode("utf-8")
    ).hexdigest()

    if lock.get("generated_sha256") != generated_hash:
        fail("generated hash mismatch; run build-contract.sh")


def main() -> None:
    if not CONTRACT_PATH.exists():
        fail(f"missing contract file: {CONTRACT_PATH}")
    if not REQUIRED_CLAUSES_PATH.exists():
        fail(f"missing required clauses file: {REQUIRED_CLAUSES_PATH}")

    contract_text = CONTRACT_PATH.read_text(encoding="utf-8")
    clauses_text = REQUIRED_CLAUSES_PATH.read_text(encoding="utf-8")

    verify_required_clauses(contract_text, clauses_text)
    required_modules = parse_required_modules(contract_text)
    if not required_modules:
        fail("missing required modules in source contract")
    module_texts = verify_module_contracts(required_modules)
    verify_lock(contract_text, required_modules, module_texts)

    print("verify ok")


if __name__ == "__main__":
    main()
