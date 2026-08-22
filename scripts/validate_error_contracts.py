#!/usr/bin/env python3
"""Validate @error Gherkin scenarios against errors.json.

Behavior lives in .feature files. errors.json is the declared PORTO_* catalog.
This check ensures:
- every @error scenario asserts a PORTO_* code that exists in the catalog
- every referenced PORTO_* is declared
- every @scenario: id among @error scenarios is unique
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Iterable
from pathlib import Path
from typing import Any

from gherkin.parser import Parser

PORTO_CODE_REGEX = re.compile(r"PORTO_[A-Z0-9_]+")
SCENARIO_TAG_PREFIX = "@scenario:"


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate error scenarios vs errors.json")
    parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    features_root = project_root / "porto_features" / "features"
    errors_path = project_root / "porto_features" / "errors.json"

    errors_doc = json.loads(errors_path.read_text(encoding="utf-8"))
    declared = {str(row["code"]) for row in errors_doc.get("codes", [])}
    if not declared:
        raise SystemExit(f"{errors_path}: no codes declared")

    problems: list[str] = []
    seen_codes: set[str] = set()
    seen_scenario_ids: dict[str, str] = {}
    scenario_count = 0

    for feature_path in sorted(features_root.rglob("*.feature")):
        for row in iter_error_scenarios(feature_path, features_root):
            scenario_count += 1
            seen_codes.add(row["porto_code"])
            if row["porto_code"] not in declared:
                problems.append(
                    f"{row['feature']}: scenario {row['scenario_id']} uses undeclared "
                    f"{row['porto_code']} (add to errors.json or fix the step)"
                )
            prior = seen_scenario_ids.get(row["scenario_id"])
            if prior is not None:
                problems.append(
                    f"duplicate @scenario: id {row['scenario_id']!r} in "
                    f"{prior} and {row['feature']}"
                )
            else:
                seen_scenario_ids[row["scenario_id"]] = row["feature"]

    if problems:
        print("❌ Error scenario contract mismatch:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        raise SystemExit(1)

    print(
        f"✅ {scenario_count} @error scenarios; "
        f"{len(seen_scenario_ids)} unique scenario ids; "
        f"{len(seen_codes)} distinct PORTO_* codes ⊆ errors.json ({len(declared)} declared)"
    )


def iter_error_scenarios(feature_path: Path, features_root: Path) -> list[dict[str, Any]]:
    parser = Parser()
    doc = parser.parse(feature_path.read_text(encoding="utf-8"))
    feature = doc.get("feature")
    if not feature:
        return []

    rel = feature_path.relative_to(features_root).as_posix()
    feature_tags = node_tags(feature)
    rows: list[dict[str, Any]] = []

    for child in iter_scenario_nodes(feature):
        scenario_obj = child["scenario"]
        scenario_tags = node_tags(scenario_obj)
        tags = normalize_tags(feature_tags, scenario_tags, feature_path.name)
        if "@error" not in tags:
            continue
        scenario_id = extract_scenario_id(scenario_tags, rel)
        porto_code = extract_porto_code(scenario_obj.get("steps", []), scenario_id, rel)
        rows.append(
            {
                "scenario_id": scenario_id,
                "porto_code": porto_code,
                "feature": rel,
                "tags": tags,
            }
        )
    return rows


def iter_scenario_nodes(feature: dict[str, Any]) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    for child in feature.get("children", []):
        if child.get("scenario"):
            nodes.append(child)
        elif child.get("rule"):
            for rule_child in child["rule"].get("children", []):
                if rule_child.get("scenario"):
                    nodes.append(rule_child)
    return nodes


def node_tags(node: dict[str, Any]) -> list[str]:
    tags: list[str] = []
    for tag in node.get("tags", []):
        name = tag.get("name", "")
        if name:
            tags.append(name)
    return tags


def extract_scenario_id(tags: Iterable[str], rel: str) -> str:
    scenario_ids = [
        tag[len(SCENARIO_TAG_PREFIX) :] for tag in tags if tag.startswith(SCENARIO_TAG_PREFIX)
    ]
    if not scenario_ids:
        raise SystemExit(f"{rel}: @error scenario missing {SCENARIO_TAG_PREFIX} tag")
    if len(scenario_ids) > 1:
        raise SystemExit(f"{rel}: multiple {SCENARIO_TAG_PREFIX} tags: {scenario_ids}")
    return scenario_ids[0]


def extract_porto_code(steps: Iterable[dict[str, Any]], scenario_id: str, rel: str) -> str:
    matches: set[str] = set()
    for step in steps:
        match = PORTO_CODE_REGEX.search(step.get("text") or "")
        if match:
            matches.add(match.group(0))
    if len(matches) == 1:
        return next(iter(matches))
    if not matches:
        raise SystemExit(f"{rel}: scenario {scenario_id} missing PORTO_* code step")
    raise SystemExit(f"{rel}: scenario {scenario_id} has multiple PORTO_* codes: {sorted(matches)}")


def normalize_tags(feature_tags: list[str], scenario_tags: list[str], filename: str) -> list[str]:
    tags: list[str] = []
    for tag in feature_tags:
        if tag not in tags:
            tags.append(tag)
    for tag in scenario_tags:
        if tag.startswith(SCENARIO_TAG_PREFIX):
            continue
        if tag not in tags:
            tags.append(tag)
    if filename == "errors.feature" and "@error" not in tags:
        tags.append("@error")
    return tags


if __name__ == "__main__":
    main()
