#!/usr/bin/env python3
from __future__ import annotations

from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
import json
import re
import sys


ROOT = Path("governance/agent-contract")
SOURCE_PATH = ROOT / "source/contract.yaml"
MODULES_DIR = ROOT / "modules"
GENERATED_DIR = ROOT / "generated"


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


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
            item = re.match(r"^\s{4}-\s*([A-Za-z0-9_-]+)\s*$", line)
            if item:
                required.append(item.group(1))
                continue
            if re.match(r"^\s{2}[A-Za-z0-9_]+:\s*$", line):
                in_required = False

    return required


def parse_contract(text: str) -> dict[str, object]:
    version_match = re.search(r"(?m)^version:\s*(\d+)\s*$", text)
    project_match = re.search(r"(?m)^\s*project:\s*([^\n#]+?)\s*$", text)
    if version_match is None:
        fail("cannot parse version from contract.yaml")
    if project_match is None:
        fail("cannot parse meta.project from contract.yaml")

    principles = re.findall(r"(?m)^\s*-\s*id:\s*([A-Za-z0-9_-]+)\s*$", text)
    stages = re.findall(r"(?m)^\s*-\s*(audit|optimize|fill_gap|intake|plan|execute|verify|report)\s*$", text)

    if not principles:
        fail("cannot parse principles from contract.yaml")
    if not stages:
        fail("cannot parse workflow stages from contract.yaml")

    required_modules = parse_required_modules(text)
    if not required_modules:
        fail("cannot parse required modules from contract.yaml")

    unique_stages: list[str] = []
    for stage in stages:
        if stage not in unique_stages:
            unique_stages.append(stage)

    return {
        "version": int(version_match.group(1)),
        "project": project_match.group(1).strip(),
        "principles": principles,
        "stages": unique_stages,
        "required_modules": required_modules,
    }


def load_module_contract(module_name: str) -> dict[str, str]:
    path = MODULES_DIR / module_name / "contract.yaml"
    if not path.exists():
        fail(f"missing module contract: {path}")

    text = path.read_text(encoding="utf-8")
    if re.search(rf"(?m)^module:\s*{re.escape(module_name)}\s*$", text) is None:
        fail(f"module contract mismatch for '{module_name}': expected module: {module_name}")

    description_match = re.search(r'(?m)^description:\s*"?(.*?)"?\s*$', text)
    description = description_match.group(1).strip() if description_match else "No description."

    for stage in ("audit", "optimize", "fill_gap"):
        if re.search(rf"(?m)^\s*-\s*{re.escape(stage)}\s*$", text) is None:
            fail(f"missing stage '{stage}' in module contract: {path}")

    return {
        "name": module_name,
        "path": str(path),
        "description": description,
        "text": text,
    }


def render_template(template: str, data: dict[str, object], modules: list[dict[str, str]]) -> str:
    principles = data["principles"]
    stages = data["stages"]
    if not isinstance(principles, list):
        fail("invalid parsed principles data")
    if not isinstance(stages, list):
        fail("invalid parsed stages data")

    principle_lines = "\n".join(f"- `{item}`" for item in principles)
    workflow_lines = "\n".join(f"- `{item}`" for item in stages)
    module_lines = "\n".join(
        f"- `{module['name']}`: {module['description']} (`{module['path']}`)"
        for module in modules
    )
    if not module_lines:
        module_lines = "- _none_"

    replacements = {
        "{{source_path}}": str(SOURCE_PATH),
        "{{project}}": str(data["project"]),
        "{{version}}": str(data["version"]),
        "{{principle_lines}}": principle_lines,
        "{{workflow_lines}}": workflow_lines,
        "{{module_count}}": str(len(modules)),
        "{{module_lines}}": module_lines,
    }
    output = template
    for key, value in replacements.items():
        output = output.replace(key, value)
    return output


def write_output(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def main() -> None:
    if not SOURCE_PATH.exists():
        fail(f"missing source contract: {SOURCE_PATH}")

    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    source_text = SOURCE_PATH.read_text(encoding="utf-8")
    data = parse_contract(source_text)
    required_modules = data["required_modules"]
    if not isinstance(required_modules, list):
        fail("invalid required modules list")

    modules: list[dict[str, str]] = [load_module_contract(module_name) for module_name in required_modules]

    outputs = {
        "AGENTS.generated.md": ROOT / "templates/agents.md.tmpl",
        "CLAUDE.generated.md": ROOT / "templates/claude.md.tmpl",
        "cursor.generated.mdc": ROOT / "templates/cursor-rule.tmpl",
    }

    rendered_by_file: dict[str, str] = {}
    for output_name, template_path in outputs.items():
        if not template_path.exists():
            fail(f"missing template: {template_path}")
        template_text = template_path.read_text(encoding="utf-8")
        rendered = render_template(template_text, data, modules)
        rendered_by_file[output_name] = rendered
        write_output(GENERATED_DIR / output_name, rendered)

    combined_output_hash = sha256(
        "".join(rendered_by_file[name] for name in sorted(rendered_by_file)).encode("utf-8")
    ).hexdigest()
    source_hash = sha256(source_text.encode("utf-8")).hexdigest()
    module_source_hash = sha256(
        "".join(module["text"] for module in sorted(modules, key=lambda item: item["name"])).encode("utf-8")
    ).hexdigest()
    combined_source_hash = sha256((source_text + module_source_hash).encode("utf-8")).hexdigest()

    stable_lock = {
        "version": data["version"],
        "required_modules": sorted(required_modules),
        "source_sha256": source_hash,
        "module_source_sha256": module_source_hash,
        "combined_source_sha256": combined_source_hash,
        "generated_sha256": combined_output_hash,
        "files": sorted(rendered_by_file),
    }

    lock_path = ROOT / "contract.lock.json"
    generated_at_utc = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    if lock_path.exists():
        try:
            existing_lock = json.loads(lock_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            existing_lock = None

        if isinstance(existing_lock, dict):
            previous_stable = {k: existing_lock.get(k) for k in stable_lock}
            if previous_stable == stable_lock:
                previous_generated_at = existing_lock.get("generated_at_utc")
                if isinstance(previous_generated_at, str) and previous_generated_at:
                    generated_at_utc = previous_generated_at

    lock = {
        **stable_lock,
        "generated_at_utc": generated_at_utc,
    }

    lock_path.write_text(
      json.dumps(lock, indent=2, ensure_ascii=True) + "\n",
      encoding="utf-8",
    )

    print("build ok")


if __name__ == "__main__":
    main()
