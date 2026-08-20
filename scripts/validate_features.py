#!/usr/bin/env python3
"""
Gherkin Feature File Validator and Linter

Validates that all .feature files in porto_features/features/:
- Are valid Gherkin syntax
- Have at least one scenario
- Declare @sdk or @adapters on the Feature (not legacy @offline/@online)
- Avoid legacy porto-data / SDK vocabulary
- Pass gherlint linting rules

Lab matrix indexes live under labs/matrix/ (validated in Porto SDK Lab).
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

try:
    from gherkin.parser import Parser
except ImportError:
    print("❌ Error: gherkin-official package not installed")
    print("   Install with: pip install gherkin-official")
    sys.exit(1)

try:
    import gherlint
except ImportError:
    print("⚠️  Warning: gherlint package not installed")
    print("   Install with: pip install gherlint")
    print("   Linting will be skipped")
    gherlint = None

LAYER_TAGS = frozenset({"sdk", "adapters"})
SCOPE_CORE_TAG = "core"
SCOPE_OPERATOR_PREFIX = "operator:"
SCOPE_WIRE_PREFIX = "wire:"
DEPRECATED_LAYER_TAGS = frozenset({"offline", "online", "capabilities", "api"})
ADAPTER_SUB_TAGS = frozenset({"canary", "heavy"})
ADAPTER_ERROR_SUB_TAGS = frozenset({"error"})
DEPRECATED_ADAPTER_SUB_TAGS = frozenset({"release", "full"})
ADAPTER_BEHAVIOR_FILENAMES = frozenset({"marks.feature", "errors.feature"})

DEPRECATED_NATIVE_PRODUCT_IDS = frozenset(
    {
        "letter_standard",
        "letter_compact",
        "letter_large",
        "letter_maxi",
        "merchandise",
    }
)

DEPRECATED_SERVICE_IDS = frozenset(
    {
        "registered_mail",
        "registered_mail_mailbox",
        "registered_mail_return_receipt",
        "registered_mail_personal",
        "registered_mail_personal_return_receipt",
    }
)

LEGACY_LETTER_TYPE_ENUM = re.compile(
    r'the letter type is\s+"([A-Z_]+)"|with type\s+"([A-Z_]+)"|letter type\s+"([A-Z_]+)"',
    re.IGNORECASE,
)

STALE_CATALOG_REFERENCES = (
    "data_links.json",
    "dimension_ids",
    "supported_zones",
)

IMPLEMENTATION_TOKEN_WARNINGS = (
    "Porto SDK client",
    "CLI ",
)

CLASS_NAME_IN_STEP = re.compile(
    r"\b(?:PortoSDK|PortoClient|LetterType|[A-Z][a-z]+(?:Client|Resolver|Service|Exception))\b"
)

NON_CANONICAL_COUNTRY_STEP = re.compile(
    r'(?:destination country|the destination country is)\s+"',
    re.IGNORECASE,
)

NON_CANONICAL_WEIGHT_STEP = re.compile(
    r"\bthe weight is \d+ grams|(?<!I have )\bweight \d+ grams|(?<!I have )\bweight <weight> grams",
    re.IGNORECASE,
)


def _feature_tags(feature: dict) -> set[str]:
    tags: set[str] = set()
    for tag in feature.get("tags", []):
        name = tag.get("name", "")
        if name.startswith("@"):
            tags.add(name[1:])
    return tags


def _node_tags(node: dict) -> set[str]:
    tags: set[str] = set()
    for tag in node.get("tags", []):
        name = tag.get("name", "")
        if name.startswith("@"):
            tags.add(name[1:])
    return tags


def _collect_tag_casing_errors(feature: dict, relative_path: Path) -> list[str]:
    """Reject non-lowercase Gherkin tags (@sdk not @SDK, @heavy not @Heavy)."""
    errors: list[str] = []

    def check_tag(raw: str, context_label: str) -> None:
        if not raw.startswith("@"):
            return
        body = raw[1:]
        if body != body.lower():
            errors.append(
                f"❌ {relative_path}: {context_label} tag '{raw}' must be lowercase — "
                f"use '@{body.lower()}' (see docs/scenario-policy.md)"
            )

    for tag in feature.get("tags", []):
        check_tag(tag.get("name", ""), "Feature")

    for child in _iter_scenario_nodes(feature):
        scenario_obj = child["scenario"]
        scenario_name = scenario_obj.get("name", "Unnamed")
        for tag in scenario_obj.get("tags", []):
            check_tag(tag.get("name", ""), f"Scenario '{scenario_name}'")

    return errors


def _collect_vocabulary_errors(content: str, relative_path: Path) -> list[str]:
    errors: list[str] = []
    for native_id in DEPRECATED_NATIVE_PRODUCT_IDS:
        if f'"{native_id}"' in content or f"'{native_id}'" in content:
            errors.append(
                f"❌ {relative_path}: Legacy native product id '{native_id}' — "
                "use porto_id buckets in Given steps and current native id in Then assertions"
            )
    for service_id in DEPRECATED_SERVICE_IDS:
        if f'"{service_id}"' in content:
            errors.append(
                f"❌ {relative_path}: Legacy service id '{service_id}' — "
                "use service porto_id in Given and native id (e.g. einschreiben) in Then"
            )
    for match in LEGACY_LETTER_TYPE_ENUM.finditer(content):
        token = next(g for g in match.groups() if g)
        errors.append(
            f"❌ {relative_path}: Legacy letter type enum '{token}' — "
            'use `the letter porto_id is "<bucket>"` (small, medium, large, extra_large)'
        )
    for stale in STALE_CATALOG_REFERENCES:
        if stale in content:
            errors.append(
                f"❌ {relative_path}: Stale catalog reference '{stale}' — "
                "align with porto-data bundle layout (graph.json, envelope_ids, zones)"
            )
    if NON_CANONICAL_COUNTRY_STEP.search(content):
        errors.append(
            f"❌ {relative_path}: Non-canonical destination country phrasing — "
            'use `I want to send a letter to country "<country_code>"` (docs/vocabulary.md)'
        )
    if NON_CANONICAL_WEIGHT_STEP.search(content):
        errors.append(
            f"❌ {relative_path}: Non-canonical weight phrasing — "
            "use `the letter weight is <weight> grams` (docs/vocabulary.md)"
        )
    return errors


def _collect_style_warnings(content: str, relative_path: Path) -> list[str]:
    """Warn on implementation leakage and non-canonical step phrasing."""
    warnings: list[str] = []

    for token in IMPLEMENTATION_TOKEN_WARNINGS:
        if token in content:
            warnings.append(
                f"⚠️  {relative_path}: Implementation token '{token.strip()}' in steps — "
                "prefer SDK-agnostic vocabulary (see docs/vocabulary.md)"
            )

    for match in CLASS_NAME_IN_STEP.finditer(content):
        class_name = match.group(0)
        warnings.append(
            f"⚠️  {relative_path}: Class-like token '{class_name}' in steps — "
            "Gherkin must stay implementation-agnostic"
        )

    return warnings


def _validate_layer_tags(feature_tags: set[str], relative_path: Path) -> list[str]:
    errors: list[str] = []
    warnings: list[str] = []

    deprecated = {t for t in feature_tags if t.lower() in DEPRECATED_LAYER_TAGS}
    if deprecated:
        warnings.append(
            f"⚠️  {relative_path}: Deprecated tag(s) {sorted(t.lower() for t in deprecated)} — "
            "use @sdk or @adapters (see docs/matrix.md)"
        )

    layer = {t.lower() for t in feature_tags if t.lower() in LAYER_TAGS}
    if len(layer) == 0:
        errors.append(
            f"❌ {relative_path}: Feature must declare @sdk or @adapters "
            "(see docs/scenario-policy.md)"
        )
    elif len(layer) > 1:
        errors.append(f"❌ {relative_path}: Feature must declare exactly one of @sdk or @adapters")

    if "adapters" in layer and any(t.lower() == "api" for t in feature_tags):
        errors.append(
            f"❌ {relative_path}: Drop @api — @adapters already implies carrier integration"
        )

    if any(t.lower() in DEPRECATED_ADAPTER_SUB_TAGS for t in feature_tags):
        errors.append(
            f"❌ {relative_path}: @release/@full are removed — use @heavy on adapter scenarios"
        )

    return errors + warnings


def _adapter_behavior_file(relative_path: Path) -> str | None:
    """Return marks.feature or errors.feature when under adapters/{provider}/{integration}/."""
    posix = relative_path.as_posix()
    if "/features/adapters/" not in posix:
        return None
    name = relative_path.name
    if name in ADAPTER_BEHAVIOR_FILENAMES:
        return name
    return None


def _validate_adapter_scenario_tags(
    feature_tags: set[str], scenarios: list[dict], relative_path: Path
) -> list[str]:
    """Execution features need @canary/@heavy; errors features need @error."""
    if "adapters" not in {t.lower() for t in feature_tags}:
        return []

    behavior = _adapter_behavior_file(relative_path)
    required = ADAPTER_ERROR_SUB_TAGS if behavior == "errors.feature" else ADAPTER_SUB_TAGS
    label = "@error" if behavior == "errors.feature" else "@canary or @heavy"

    has_lane_tag = False
    for scenario in scenarios:
        scenario_tags = {t.lower() for t in _node_tags(scenario["scenario"])}
        if scenario_tags & required:
            has_lane_tag = True
            break

    if not has_lane_tag:
        return [
            f"❌ {relative_path}: @adapters {behavior or 'feature'} must tag at least one "
            f"scenario {label} (see docs/scenario-policy.md)"
        ]
    return []


def _scope_tags(feature_tags: set[str]) -> tuple[str | None, str | None]:
    """Return (core|operator_id|None, wire_id|None) from scope tags."""
    operator_id: str | None = None
    wire_id: str | None = None
    tags_lower = {t.lower() for t in feature_tags}
    has_core = SCOPE_CORE_TAG in tags_lower
    for tag in feature_tags:
        lower = tag.lower()
        if lower.startswith(SCOPE_OPERATOR_PREFIX):
            operator_id = lower[len(SCOPE_OPERATOR_PREFIX) :]
        elif lower.startswith(SCOPE_WIRE_PREFIX):
            wire_id = lower[len(SCOPE_WIRE_PREFIX) :]
    if has_core:
        return SCOPE_CORE_TAG, wire_id
    return operator_id, wire_id


def _enforce_scope_path_layout(relative_path: Path) -> bool:
    """True when the file lives under the published features tree."""
    posix = relative_path.as_posix()
    return "/features/sdk/" in posix or "/features/adapters/" in posix


def _validate_scope_tags(feature_tags: set[str], relative_path: Path) -> list[str]:
    """Validate @core / @operator:* / @wire:* alignment with folder layout."""
    errors: list[str] = []
    if not _enforce_scope_path_layout(relative_path):
        return errors

    path_posix = relative_path.as_posix()
    layer = {t.lower() for t in feature_tags if t.lower() in LAYER_TAGS}
    if not layer:
        return errors

    scope, wire_id = _scope_tags(feature_tags)
    operator_tags = [t for t in feature_tags if t.lower().startswith(SCOPE_OPERATOR_PREFIX)]

    if "sdk" in layer:
        if scope == SCOPE_CORE_TAG and operator_tags:
            errors.append(
                f"❌ {relative_path}: @core and @operator:* are mutually exclusive on @sdk features"
            )
        elif scope != SCOPE_CORE_TAG:
            if len(operator_tags) == 0:
                errors.append(
                    f"❌ {relative_path}: @sdk feature must declare @core or exactly one @operator:{{id}}"
                )
            elif len(operator_tags) > 1:
                errors.append(
                    f"❌ {relative_path}: @sdk feature must declare at most one @operator:{{id}}"
                )
            elif scope and f"/providers/{scope}/" not in path_posix:
                errors.append(
                    f"❌ {relative_path}: @operator:{scope} must live under sdk/providers/{scope}/"
                )
        elif "/sdk/core/" not in path_posix:
            errors.append(f"❌ {relative_path}: @core features must live under sdk/core/")

    if "adapters" in layer:
        if len(operator_tags) != 1:
            errors.append(
                f"❌ {relative_path}: @adapters feature must declare exactly one @operator:{{id}}"
            )
        wire_tags = [t for t in feature_tags if t.lower().startswith(SCOPE_WIRE_PREFIX)]
        if len(wire_tags) != 1:
            errors.append(
                f"❌ {relative_path}: @adapters feature must declare exactly one @wire:{{id}}"
            )
        if scope and scope != SCOPE_CORE_TAG and f"/adapters/{scope}/" not in path_posix:
            errors.append(
                f"❌ {relative_path}: @operator:{scope} must live under adapters/{scope}/"
            )
        if wire_id and _adapter_behavior_file(relative_path):
            parts = path_posix.split("/features/adapters/", 1)[-1].split("/")
            if len(parts) >= 2 and parts[1] != wire_id:
                errors.append(
                    f"❌ {relative_path}: @wire:{wire_id} must match integration directory "
                    f"adapters/{{provider}}/{wire_id}/"
                )

    return errors


def _iter_scenario_nodes(feature: dict) -> list[dict]:
    """Yield scenario/outline nodes from feature children and nested Rules."""
    nodes: list[dict] = []
    for child in feature.get("children", []):
        if child.get("scenario"):
            nodes.append(child)
        elif child.get("rule"):
            for rule_child in child["rule"].get("children", []):
                if rule_child.get("scenario"):
                    nodes.append(rule_child)
    return nodes


def validate_feature_file(file_path: Path) -> tuple[bool, list[str]]:
    """Validate a single feature file."""
    errors: list[str] = []
    relative_path = file_path.relative_to(Path.cwd())

    try:
        content = file_path.read_text(encoding="utf-8")
        parser = Parser()
        gherkin_document = parser.parse(content)

        if not gherkin_document.get("feature"):
            errors.append(f"❌ {relative_path}: Missing Feature declaration")
            return False, errors

        feature = gherkin_document["feature"]
        errors.extend(_collect_tag_casing_errors(feature, relative_path))
        feature_tags = _feature_tags(feature)
        errors.extend(_validate_layer_tags(feature_tags, relative_path))
        errors.extend(_validate_scope_tags(feature_tags, relative_path))

        scenarios = _iter_scenario_nodes(feature)

        if len(scenarios) == 0:
            errors.append(f"❌ {relative_path}: Feature has no scenarios")
            return False, errors

        scenario_names = [s["scenario"]["name"] for s in scenarios]
        duplicates = [
            name for i, name in enumerate(scenario_names) if scenario_names.index(name) != i
        ]
        if duplicates:
            unique_duplicates = list(set(duplicates))
            errors.append(
                f"⚠️  {relative_path}: Duplicate scenario names: {', '.join(unique_duplicates)}"
            )

        for scenario in scenarios:
            scenario_obj = scenario["scenario"]
            scenario_name = scenario_obj.get("name", "Unnamed")
            steps = scenario_obj.get("steps", [])

            if not steps:
                errors.append(f'❌ {relative_path}: Scenario "{scenario_name}" has no steps')

        errors.extend(_validate_adapter_scenario_tags(feature_tags, scenarios, relative_path))
        errors.extend(_collect_vocabulary_errors(content, relative_path))
        errors.extend(_collect_style_warnings(content, relative_path))

        scenario_count = len(scenarios)
        print(
            f"✅ {relative_path}: Valid "
            f"({scenario_count} scenario{'s' if scenario_count != 1 else ''})"
        )

        actual_errors = [e for e in errors if not e.startswith("⚠️")]
        return len(actual_errors) == 0, errors

    except Exception as e:
        error_msg = str(e)
        if "parse" in error_msg.lower() or "gherkin" in error_msg.lower():
            errors.append(f"❌ {relative_path}: Parse error - {error_msg}")
        else:
            errors.append(f"❌ {relative_path}: Error - {error_msg}")
        return False, errors


def find_feature_files(directory: Path) -> list[Path]:
    """Recursively find all .feature files in directory."""
    if not directory.exists():
        return []
    return sorted(p for p in directory.rglob("*.feature") if p.is_file())


def run_gherlint(features_dir: Path) -> tuple[bool, list[str]]:
    """Run gherlint on feature files."""
    if gherlint is None:
        return True, []

    errors: list[str] = []
    try:
        project_root = Path(__file__).parent.parent
        venv_gherlint = project_root / "venv" / "bin" / "gherlint"
        gherlint_cmd = str(venv_gherlint) if venv_gherlint.exists() else "gherlint"

        result = subprocess.run(
            [gherlint_cmd, "lint", str(features_dir)],
            capture_output=True,
            text=True,
            cwd=project_root,
        )

        lint_output = (result.stdout + result.stderr).strip()

        if result.returncode != 0:
            lint_errors = result.stdout + result.stderr
            if lint_errors.strip():
                errors.append(f"❌ Gherkin linting errors:\n{lint_errors}")
                return False, errors
        else:
            if lint_output:
                errors.append(f"⚠️  Gherkin linting hints:\n{lint_output}")
            print("✅ Gherkin linting passed")

        return True, errors
    except FileNotFoundError:
        errors.append("⚠️  gherlint command not found, skipping linting")
        return True, errors
    except Exception as e:
        errors.append(f"⚠️  Error running gherlint: {str(e)}")
        return True, errors


def main() -> None:
    """Main validation function."""
    project_root = Path(__file__).parent.parent
    features_dir = project_root / "porto_features" / "features"
    print("🔍 Validating Gherkin feature files...\n")

    feature_files = find_feature_files(features_dir)

    if not feature_files:
        print("❌ No .feature files found in porto_features/features/ directory")
        sys.exit(1)

    all_errors: list[str] = []
    all_warnings: list[str] = []
    has_errors = False

    print("📝 Step 1: Syntax and vocabulary validation")
    print("-" * 50)
    for file_path in feature_files:
        is_valid, errors = validate_feature_file(file_path)
        file_has_errors = False
        for error in errors:
            if error.startswith("⚠️"):
                all_warnings.append(error)
            else:
                all_errors.append(error)
                file_has_errors = True
        if file_has_errors:
            has_errors = True

    print("\n🔍 Step 2: Gherkin linting")
    print("-" * 50)
    _lint_valid, lint_errors = run_gherlint(features_dir)
    lint_has_errors = False
    for error in lint_errors:
        if error.startswith("⚠️"):
            all_warnings.append(error)
        else:
            all_errors.append(error)
            lint_has_errors = True
    if lint_has_errors:
        has_errors = True

    print("\n" + "=" * 50)

    if all_warnings:
        print("\n⚠️  Warnings (non-fatal):\n")
        for warning in all_warnings:
            print(warning)

    if has_errors or all_errors:
        print("\n❌ Validation failed:\n")
        for error in all_errors:
            print(error)
        sys.exit(1)
    else:
        print("\n✅ All feature files are valid and pass linting!")
        sys.exit(0)


if __name__ == "__main__":
    main()
