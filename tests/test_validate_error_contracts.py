from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "validate_error_contracts.py"


def load_module():
    spec = spec_from_file_location("validate_error_contracts_module", SCRIPT_PATH)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_iter_error_scenarios_requires_porto_code(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    errors_dir = features_root / "sdk" / "core"
    errors_dir.mkdir(parents=True)
    (errors_dir / "errors.feature").write_text(
        """
@sdk
@core
Feature: Errors
  @scenario:core.test_error
  Scenario: Error scenario
    Then I should get Porto error code "PORTO_TEST_ERROR"
""".strip(),
        encoding="utf-8",
    )

    rows = module.iter_error_scenarios(errors_dir / "errors.feature", features_root)
    assert len(rows) == 1
    assert rows[0]["scenario_id"] == "core.test_error"
    assert rows[0]["porto_code"] == "PORTO_TEST_ERROR"
    assert "@error" in rows[0]["tags"]


def test_non_error_feature_yields_no_rows(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    (features_root / "sdk" / "core").mkdir(parents=True)
    (features_root / "sdk" / "core" / "validation.feature").write_text(
        """
@sdk
@core
Feature: Validation
  Scenario: Happy path
    When I validate the address
    Then the validation should pass
""".strip(),
        encoding="utf-8",
    )

    rows = module.iter_error_scenarios(
        features_root / "sdk" / "core" / "validation.feature", features_root
    )
    assert rows == []


def test_duplicate_scenario_ids_detected_across_features(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    a = features_root / "sdk" / "core"
    b = features_root / "adapters" / "x"
    a.mkdir(parents=True)
    b.mkdir(parents=True)
    feature_body = """
@sdk
Feature: Dup
  @error
  @scenario:dup.id
  Scenario: One
    Then I should get Porto error code "PORTO_AUTH_FAILED"
""".strip()
    (a / "errors.feature").write_text(feature_body, encoding="utf-8")
    (b / "errors.feature").write_text(feature_body, encoding="utf-8")

    seen: dict[str, str] = {}
    problems: list[str] = []
    for feature_path in sorted(features_root.rglob("*.feature")):
        for row in module.iter_error_scenarios(feature_path, features_root):
            prior = seen.get(row["scenario_id"])
            if prior is not None:
                problems.append(
                    f"duplicate @scenario: id {row['scenario_id']!r} in {prior} and {row['feature']}"
                )
            else:
                seen[row["scenario_id"]] = row["feature"]

    assert len(problems) == 1
    assert "dup.id" in problems[0]
