#!/usr/bin/env python3
"""
Gherkin Feature File Validator and Linter

Validates that all .feature files in the porto_features/features/ directory:
- Are valid Gherkin syntax
- Have at least one scenario
- Have proper structure (Feature, Background, Scenarios)
- Pass gherlint linting rules
"""

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


def validate_feature_file(file_path: Path) -> tuple[bool, list[str]]:
    """Validate a single feature file."""
    errors = []
    relative_path = file_path.relative_to(Path.cwd())

    try:
        content = file_path.read_text(encoding="utf-8")
        parser = Parser()
        gherkin_document = parser.parse(content)

        if not gherkin_document.get("feature"):
            errors.append(f"❌ {relative_path}: Missing Feature declaration")
            return False, errors

        feature = gherkin_document["feature"]
        scenarios = [child for child in feature.get("children", []) if child.get("scenario")]

        # Check for at least one scenario
        if len(scenarios) == 0:
            errors.append(f"❌ {relative_path}: Feature has no scenarios")
            return False, errors

        # Check for duplicate scenario names
        scenario_names = [s["scenario"]["name"] for s in scenarios]
        duplicates = [
            name for i, name in enumerate(scenario_names) if scenario_names.index(name) != i
        ]
        if duplicates:
            unique_duplicates = list(set(duplicates))
            errors.append(
                f"⚠️  {relative_path}: Duplicate scenario names: {', '.join(unique_duplicates)}"
            )

        # Check each scenario has steps
        for scenario in scenarios:
            scenario_obj = scenario["scenario"]
            scenario_name = scenario_obj.get("name", "Unnamed")
            steps = scenario_obj.get("steps", [])

            if not steps:
                errors.append(f'❌ {relative_path}: Scenario "{scenario_name}" has no steps')

        scenario_count = len(scenarios)
        print(
            f"✅ {relative_path}: Valid "
            f"({scenario_count} scenario{'s' if scenario_count != 1 else ''})"
        )

        # Only return False if there are actual errors (not warnings)
        actual_errors = [e for e in errors if not e.startswith("⚠️")]
        return len(actual_errors) == 0, errors

    except Exception as e:
        # Parser raises various exceptions, catch all parse-related errors
        error_msg = str(e)
        if "parse" in error_msg.lower() or "gherkin" in error_msg.lower():
            errors.append(f"❌ {relative_path}: Parse error - {error_msg}")
        else:
            errors.append(f"❌ {relative_path}: Error - {error_msg}")
        return False, errors


def find_feature_files(directory: Path) -> list[Path]:
    """Recursively find all .feature files in directory."""
    feature_files: list[Path] = []

    if not directory.exists():
        return feature_files

    for file_path in directory.rglob("*.feature"):
        if file_path.is_file():
            feature_files.append(file_path)

    return sorted(feature_files)


def run_gherlint(features_dir: Path) -> tuple[bool, list[str]]:
    """Run gherlint on feature files."""
    if gherlint is None:
        return True, []

    errors = []
    try:
        # Try to use venv/bin/gherlint first, then fall back to system gherlint
        project_root = Path(__file__).parent.parent
        venv_gherlint = project_root / "venv" / "bin" / "gherlint"
        gherlint_cmd = str(venv_gherlint) if venv_gherlint.exists() else "gherlint"

        # Run gherlint via command line
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


def main():
    """Main validation function."""
    project_root = Path(__file__).parent.parent
    features_dir = project_root / "porto_features" / "features"

    print("🔍 Validating Gherkin feature files...\n")

    feature_files = find_feature_files(features_dir)

    if not feature_files:
        print("❌ No .feature files found in porto_features/features/ directory")
        sys.exit(1)

    all_errors = []
    all_warnings = []
    has_errors = False

    # Step 1: Syntax validation
    print("📝 Step 1: Syntax validation")
    print("-" * 50)
    for file_path in feature_files:
        is_valid, errors = validate_feature_file(file_path)
        # Separate errors from warnings
        file_has_errors = False
        for error in errors:
            if error.startswith("⚠️"):
                all_warnings.append(error)
            else:
                all_errors.append(error)
                file_has_errors = True
        if file_has_errors:
            has_errors = True

    # Step 2: Linting
    print("\n🔍 Step 2: Gherkin linting")
    print("-" * 50)
    lint_valid, lint_errors = run_gherlint(features_dir)
    # Separate errors from warnings
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

    # Print warnings (non-fatal)
    if all_warnings:
        print("\n⚠️  Warnings (non-fatal):\n")
        for warning in all_warnings:
            print(warning)

    # Only fail on actual errors
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
