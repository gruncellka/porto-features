#!/usr/bin/env python3
"""
JSON Fixture Validator.

Validates that all .json fixture files in porto_features/fixtures/:
- are valid JSON
- include required address fields for address fixtures
- use string values for required address fields
"""

import json
import sys
from pathlib import Path
from typing import Any

ADDRESS_REQUIRED_FIELDS = [
    "id",
    "name",
    "street",
    "house_number",
    "postal_code",
    "city",
    "country_code",
]


def find_fixture_files(directory: Path) -> list[Path]:
    """Recursively find all .json fixture files in directory."""
    fixture_files: list[Path] = []

    if not directory.exists():
        return fixture_files

    for file_path in directory.rglob("*.json"):
        if file_path.is_file():
            fixture_files.append(file_path)

    return sorted(fixture_files)


def validate_address_fixture(file_path: Path, payload: dict[str, Any]) -> list[str]:
    """Validate address fixture fields and types."""
    errors: list[str] = []
    relative_path = file_path.relative_to(Path.cwd())

    for field in ADDRESS_REQUIRED_FIELDS:
        value = payload.get(field)
        if value is None:
            errors.append(f"❌ {relative_path}: Missing required field '{field}'")
            continue
        if not isinstance(value, str) or not value.strip():
            errors.append(f"❌ {relative_path}: Field '{field}' must be a non-empty string")

    # region_code is recommended for sanctions/regional checks.
    region_code = payload.get("region_code")
    if region_code is not None and (not isinstance(region_code, str) or not region_code.strip()):
        errors.append(
            f"❌ {relative_path}: Optional field 'region_code' must be a non-empty string"
        )

    return errors


def validate_fixture_file(file_path: Path) -> tuple[bool, list[str]]:
    """Validate one JSON fixture file."""
    errors: list[str] = []
    relative_path = file_path.relative_to(Path.cwd())

    try:
        content = file_path.read_text(encoding="utf-8")
        payload = json.loads(content)
    except Exception as exc:
        return False, [f"❌ {relative_path}: Invalid JSON - {exc}"]

    if not isinstance(payload, dict):
        return False, [f"❌ {relative_path}: Root must be a JSON object"]

    if "addresses" in file_path.parts:
        errors.extend(validate_address_fixture(file_path, payload))

    if errors:
        return False, errors

    print(f"✅ {relative_path}: Valid JSON fixture")
    return True, []


def main() -> None:
    """Main validation function."""
    project_root = Path(__file__).parent.parent
    fixtures_dir = project_root / "porto_features" / "fixtures"

    print("🔍 Validating JSON fixture files...\n")

    fixture_files = find_fixture_files(fixtures_dir)
    if not fixture_files:
        print("❌ No .json fixture files found in porto_features/fixtures/")
        sys.exit(1)

    all_errors: list[str] = []
    all_warnings: list[str] = []
    has_errors = False

    for file_path in fixture_files:
        is_valid, errors = validate_fixture_file(file_path)
        file_has_errors = False
        for error in errors:
            if error.startswith("⚠️"):
                all_warnings.append(error)
            else:
                all_errors.append(error)
                file_has_errors = True
        if not is_valid and file_has_errors:
            has_errors = True

    print("\n" + "=" * 50)

    if all_warnings:
        print("\n⚠️  Warnings (non-fatal):\n")
        for warning in all_warnings:
            print(warning)

    if has_errors:
        print("\n❌ Fixture validation failed:\n")
        for error in all_errors:
            print(error)
        sys.exit(1)

    print("\n✅ All fixtures are valid!")
    sys.exit(0)


if __name__ == "__main__":
    main()
