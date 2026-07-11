#!/usr/bin/env python3
"""
Gherkin Feature File Validator and Linter

Validates that all .feature files in porto_features/features/:
- Are valid Gherkin syntax
- Have at least one scenario
- Declare @sdk or @adapters on the Feature (not legacy @offline/@online)
- Avoid legacy porto-data / SDK vocabulary
- Pass gherlint linting rules

Also validates matrix/ YAML indexes (sdk.yaml, canary.yaml, orders.generated.yaml).
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

try:
    import yaml
except ImportError:
    yaml = None

LAYER_TAGS = frozenset({"sdk", "adapters"})
SCOPE_CORE_TAG = "core"
SCOPE_OPERATOR_PREFIX = "operator:"
SCOPE_WIRE_PREFIX = "wire:"
DEPRECATED_LAYER_TAGS = frozenset({"offline", "online", "capabilities", "api"})
ADAPTER_SUB_TAGS = frozenset({"canary", "full"})
DEPRECATED_ADAPTER_SUB_TAGS = frozenset({"release"})

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
    r'(?:destination country|the destination country is)\s+"[A-Z]{2}"',
    re.IGNORECASE,
)


def _feature_tags(feature: dict) -> set[str]:
    tags: set[str] = set()
    for tag in feature.get("tags", []):
        name = tag.get("name", "")
        if name.startswith("@"):
            tags.add(name[1:])
    return tags


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

    if NON_CANONICAL_COUNTRY_STEP.search(content):
        warnings.append(
            f"⚠️  {relative_path}: Non-canonical destination country phrasing — "
            'use `I want to send a letter to country "<country_code>"` (docs/vocabulary.md)'
        )

    return warnings


def _validate_layer_tags(feature_tags: set[str], relative_path: Path) -> list[str]:
    errors: list[str] = []
    warnings: list[str] = []

    deprecated = feature_tags & DEPRECATED_LAYER_TAGS
    if deprecated:
        warnings.append(
            f"⚠️  {relative_path}: Deprecated tag(s) {sorted(deprecated)} — "
            "use @sdk or @adapters (see docs/matrix.md)"
        )

    layer = feature_tags & LAYER_TAGS
    if len(layer) == 0:
        errors.append(
            f"❌ {relative_path}: Feature must declare @sdk or @adapters "
            "(see docs/scenario-policy.md)"
        )
    elif len(layer) > 1:
        errors.append(f"❌ {relative_path}: Feature must declare exactly one of @sdk or @adapters")

    if "adapters" in feature_tags and "api" in feature_tags:
        errors.append(
            f"❌ {relative_path}: Drop @api — @adapters already implies carrier integration"
        )

    if feature_tags & DEPRECATED_ADAPTER_SUB_TAGS:
        warnings.append(
            f"⚠️  {relative_path}: @release is deprecated — use @full on adapter scenarios"
        )

    return errors + warnings


def _scope_tags(feature_tags: set[str]) -> tuple[str | None, str | None]:
    """Return (core|operator_id|None, wire_id|None) from scope tags."""
    operator_id: str | None = None
    wire_id: str | None = None
    has_core = SCOPE_CORE_TAG in feature_tags
    for tag in feature_tags:
        if tag.startswith(SCOPE_OPERATOR_PREFIX):
            operator_id = tag[len(SCOPE_OPERATOR_PREFIX) :]
        elif tag.startswith(SCOPE_WIRE_PREFIX):
            wire_id = tag[len(SCOPE_WIRE_PREFIX) :]
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
    layer = feature_tags & LAYER_TAGS
    if not layer:
        return errors

    scope, wire_id = _scope_tags(feature_tags)
    operator_tags = [t for t in feature_tags if t.startswith(SCOPE_OPERATOR_PREFIX)]

    if "sdk" in feature_tags:
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

    if "adapters" in feature_tags:
        if len(operator_tags) != 1:
            errors.append(
                f"❌ {relative_path}: @adapters feature must declare exactly one @operator:{{id}}"
            )
        wire_tags = [t for t in feature_tags if t.startswith(SCOPE_WIRE_PREFIX)]
        if len(wire_tags) != 1:
            errors.append(
                f"❌ {relative_path}: @adapters feature must declare exactly one @wire:{{id}}"
            )
        if scope and scope != SCOPE_CORE_TAG and f"/adapters/{scope}/" not in path_posix:
            errors.append(
                f"❌ {relative_path}: @operator:{scope} must live under adapters/{scope}/"
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


def _ref_feature_path(ref: str) -> str:
    """Extract feature path from ref like sdk/foo.feature:Scenario:Name."""
    return _parse_matrix_ref(ref)[0]


def _parse_matrix_ref(ref: str) -> tuple[str, str | None, str | None]:
    """Return (feature_rel_path, ref_kind, scenario_name). kind is None for file-only refs."""
    head, *tail = ref.split(":")
    if not head.endswith(".feature"):
        head = f"{head}.feature" if "/" in head else f"{head}.feature"
    if not tail:
        return head, None, None
    kind = tail[0]
    name = ":".join(tail[1:])
    if not name:
        return head, kind, None
    return head, kind, name


def _resolve_feature_path(features_dir: Path, rel: str) -> Path | None:
    feature_path = features_dir / rel
    if feature_path.is_file():
        return feature_path
    basename = Path(rel).name
    for candidate in features_dir.rglob(basename):
        if candidate.is_file():
            return candidate
    return None


def _collect_feature_scenario_names(feature_path: Path) -> tuple[set[str], set[str]]:
    """Return (scenario_names, outline_names) from a feature file."""
    parser = Parser()
    gherkin_document = parser.parse(feature_path.read_text(encoding="utf-8"))
    feature = gherkin_document.get("feature")
    if not feature:
        return set(), set()

    scenarios: set[str] = set()
    outlines: set[str] = set()
    for child in _iter_scenario_nodes(feature):
        scenario_obj = child["scenario"]
        name = scenario_obj.get("name", "")
        keyword = scenario_obj.get("keyword", "Scenario")
        if keyword == "Scenario Outline":
            outlines.add(name)
        else:
            scenarios.add(name)
    return scenarios, outlines


def _validate_matrix_ref(ref: str, features_dir: Path, context: str) -> list[str]:
    """Validate matrix ref resolves to an existing feature and optional scenario/outline."""
    rel, kind, name = _parse_matrix_ref(ref)
    feature_path = _resolve_feature_path(features_dir, rel)
    if feature_path is None:
        expected = features_dir / rel
        alt = features_dir / "sdk" / Path(rel).name
        return [
            f"❌ {context}: ref '{ref}' — feature file not found (expected {expected} or {alt})"
        ]

    if kind is None or name is None:
        return []

    scenarios, outlines = _collect_feature_scenario_names(feature_path)
    if kind in {"Outline", "Scenario Outline"}:
        if name not in outlines:
            known = ", ".join(sorted(outlines)) or "(none)"
            return [
                f"❌ {context}: ref '{ref}' — outline '{name}' not found in {rel} "
                f"(known outlines: {known})"
            ]
        return []

    if kind == "Scenario":
        if name not in scenarios:
            known = ", ".join(sorted(scenarios)) or "(none)"
            return [
                f"❌ {context}: ref '{ref}' — scenario '{name}' not found in {rel} "
                f"(known scenarios: {known})"
            ]
        return []

    return [f"❌ {context}: ref '{ref}' — unknown ref kind '{kind}'"]


def _load_yaml(path: Path) -> dict:
    lines = [
        line
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    doc = yaml.safe_load("\n".join(lines))
    return doc if isinstance(doc, dict) else {}


def _expected_case_id(cell: dict) -> str:
    """Dot-scoped case_id from structured order cell fields."""
    parts = [cell["provider"], cell["adapter"], cell["product_id"], cell["zone_id"]]
    service_ids = cell.get("service_ids") or []
    if isinstance(service_ids, list):
        parts.extend(service_ids)
    return ".".join(parts)


def validate_matrix_files(matrix_dir: Path, features_dir: Path) -> tuple[bool, list[str]]:
    """Validate matrix YAML indexes."""
    if yaml is None:
        print("⚠️  PyYAML not installed — skipping matrix validation")
        return True, []

    errors: list[str] = []
    orders_path = matrix_dir / "orders.generated.yaml"
    canary_path = matrix_dir / "canary.yaml"
    sdk_path = matrix_dir / "sdk.yaml"
    slices_path = matrix_dir / "slices.yaml"

    for required in (slices_path, sdk_path, canary_path, orders_path):
        if not required.is_file():
            errors.append(f"❌ Missing matrix file: {required.relative_to(matrix_dir.parent)}")
    if errors:
        return False, errors

    orders_doc = _load_yaml(orders_path)
    canary_doc = _load_yaml(canary_path)
    sdk_doc = _load_yaml(sdk_path)
    slices_doc = _load_yaml(slices_path)
    known_slices = set(slices_doc.get("slices", {}).keys())

    order_ids = {row["case_id"] for row in orders_doc.get("order_cells", [])}

    for case_id in canary_doc.get("case_ids", []):
        if case_id not in order_ids:
            errors.append(
                f"❌ canary.yaml: case_id '{case_id}' not in orders.generated.yaml "
                "(must be porto-data wire subset)"
            )

    for cell in sdk_doc.get("sdk_cells", []):
        slice_name = cell.get("slice")
        if slice_name and slice_name not in known_slices:
            errors.append(
                f"❌ sdk.yaml: cell '{cell.get('cell_id')}' uses unknown slice "
                f"'{slice_name}' (define in slices.yaml)"
            )
        for ref in cell.get("refs", []):
            errors.extend(_validate_matrix_ref(ref, features_dir, "sdk.yaml"))

    for cell in orders_doc.get("order_cells", []):
        expected_id = _expected_case_id(cell)
        actual_id = cell.get("case_id")
        if actual_id != expected_id:
            errors.append(
                f"❌ orders.generated.yaml: case_id '{actual_id}' does not match "
                f"structured fields (expected '{expected_id}')"
            )
        for ref in cell.get("refs", []):
            errors.extend(_validate_matrix_ref(ref, features_dir, "orders.generated.yaml"))

    if not errors:
        print(
            f"✅ matrix/: {len(order_ids)} order_cells, "
            f"{len(canary_doc.get('case_ids', []))} canary ids, "
            f"{len(sdk_doc.get('sdk_cells', []))} sdk cells"
        )

    return len(errors) == 0, errors


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
            cwd=features_dir.parent,
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
    matrix_dir = project_root / "porto_features" / "matrix"

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

    print("\n📋 Step 2: Matrix index validation")
    print("-" * 50)
    matrix_ok, matrix_errors = validate_matrix_files(matrix_dir, features_dir)
    for error in matrix_errors:
        all_errors.append(error)
    if not matrix_ok:
        has_errors = True

    print("\n🔍 Step 3: Gherkin linting")
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
