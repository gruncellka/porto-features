#!/usr/bin/env python3
"""Validate @status Gherkin scenarios against statuses.json.

statuses.json is the declared PortoStatus catalog (contract only).
This check ensures:
- catalog codes are unique and each row has code, domain, and description
- descriptions avoid shipment, shipping, package, and sending
- every @status scenario asserts one catalog code
- every referenced code is declared
- every @scenario: id among @status scenarios is unique
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

STATUS_CODE_REGEX = re.compile(r'"([a-z][a-z0-9_]*)"')
SCENARIO_TAG_PREFIX = "@scenario:"
# Features vocabulary: letter/mark, not shipment or package. PortoMark covers stamp and label.
FORBIDDEN_STATUS_WORDS = re.compile(r"\b(shipment|shipping|package|sending)\b", re.IGNORECASE)


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate status scenarios vs statuses.json")
    parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    features_root = project_root / "porto_features" / "features"
    statuses_path = project_root / "porto_features" / "statuses.json"

    statuses_doc = json.loads(statuses_path.read_text(encoding="utf-8"))
    declared = catalog_codes(statuses_doc, statuses_path)

    problems: list[str] = []
    seen_codes: set[str] = set()
    seen_scenario_ids: dict[str, str] = {}
    scenario_count = 0

    for feature_path in sorted(features_root.rglob("*.feature")):
        for row in iter_status_scenarios(feature_path, features_root):
            scenario_count += 1
            seen_codes.add(row["status_code"])
            if row["status_code"] not in declared:
                problems.append(
                    f"{row['feature']}: scenario {row['scenario_id']} uses undeclared "
                    f"{row['status_code']} (add to statuses.json or fix the step)"
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
        print("❌ Status scenario contract mismatch:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        raise SystemExit(1)

    print(
        f"✅ {scenario_count} @status scenarios; "
        f"{len(seen_scenario_ids)} unique scenario ids; "
        f"{len(seen_codes)} distinct status codes ⊆ statuses.json ({len(declared)} declared)"
    )


def catalog_codes(doc: dict[str, Any], path: Path) -> set[str]:
    rows = doc.get("codes", [])
    if not rows:
        raise SystemExit(f"{path}: no codes declared")
    declared: set[str] = set()
    for row in rows:
        if not isinstance(row, dict):
            raise SystemExit(f"{path}: status row must be an object")
        code = str(row.get("code") or "").strip()
        domain = str(row.get("domain") or "").strip()
        description = str(row.get("description") or "").strip()
        if not code or not domain or not description:
            raise SystemExit(f"{path}: status row missing code, domain, or description")
        if code in declared:
            raise SystemExit(f"{path}: duplicate status code {code}")
        forbidden = FORBIDDEN_STATUS_WORDS.search(description)
        if forbidden:
            raise SystemExit(
                f"{path}: status {code} description uses forbidden word {forbidden.group(0)!r}"
            )
        declared.add(code)
    return declared


def iter_status_scenarios(feature_path: Path, features_root: Path) -> list[dict[str, Any]]:
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
        if "@status" not in tags:
            continue
        scenario_id = extract_scenario_id(scenario_tags, rel)
        status_code = extract_status_code(scenario_obj.get("steps", []), scenario_id, rel)
        rows.append(
            {
                "scenario_id": scenario_id,
                "status_code": status_code,
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
        raise SystemExit(f"{rel}: @status scenario missing {SCENARIO_TAG_PREFIX} tag")
    if len(scenario_ids) > 1:
        raise SystemExit(f"{rel}: multiple {SCENARIO_TAG_PREFIX} tags: {scenario_ids}")
    return scenario_ids[0]


def extract_status_code(steps: Iterable[dict[str, Any]], scenario_id: str, rel: str) -> str:
    matches: set[str] = set()
    for step in steps:
        for match in STATUS_CODE_REGEX.findall(step.get("text") or ""):
            matches.add(match)
    if len(matches) == 1:
        return next(iter(matches))
    if not matches:
        raise SystemExit(f"{rel}: scenario {scenario_id} missing quoted status code")
    raise SystemExit(f"{rel}: scenario {scenario_id} has multiple status codes: {sorted(matches)}")


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
    if filename == "status.feature" and "@status" not in tags:
        tags.append("@status")
    return tags


if __name__ == "__main__":
    main()
