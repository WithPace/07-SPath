#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys


CONTRACT_PATH = Path("governance/agent-contract/source/contract.yaml")
SCHEMA_PATH = Path("governance/agent-contract/schema/contract.schema.json")


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def must_contain(text: str, snippet: str, description: str) -> None:
    if snippet not in text:
        fail(f"missing {description}: expected snippet '{snippet}'")


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


def main() -> None:
    if not CONTRACT_PATH.exists():
        fail(f"missing contract file: {CONTRACT_PATH}")
    if not SCHEMA_PATH.exists():
        fail(f"missing schema file: {SCHEMA_PATH}")

    text = CONTRACT_PATH.read_text(encoding="utf-8")

    must_contain(text, "version:", "top-level key")
    must_contain(text, "meta:", "top-level key")
    must_contain(text, "principles:", "top-level key")
    must_contain(text, "workflow:", "top-level key")

    if re.search(r"\bid:\s*evidence_before_claim\b", text) is None:
        fail("missing required principle id: evidence_before_claim")

    for stage in ("audit", "optimize", "fill_gap"):
        if re.search(rf"^\s*-\s*{re.escape(stage)}\s*$", text, flags=re.MULTILINE) is None:
            fail(f"missing required workflow stage: {stage}")

    required_modules = parse_required_modules(text)
    expected_modules = ["orchestrator", "assessment", "training"]
    for module_name in expected_modules:
        if module_name not in required_modules:
            fail(f"missing required module declaration: {module_name}")

    print("ok")


if __name__ == "__main__":
    main()
