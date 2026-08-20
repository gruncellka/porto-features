import json
import runpy
import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "validate_error_contracts.py"

ERROR_SCENARIO = """
@sdk
Feature: Errors
  @scenario:{scenario_id}
  Scenario: Error scenario
    Then I should get Porto error code "{code}"
""".strip()


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


def _point_module_at_tmp(module, tmp_path, monkeypatch, *, codes, features: dict[str, str]) -> None:
    scripts = tmp_path / "scripts"
    scripts.mkdir()
    monkeypatch.setattr(module, "__file__", str(scripts / "validate_error_contracts.py"))
    monkeypatch.setattr(sys, "argv", ["validate_error_contracts.py"])
    root = tmp_path / "porto_features"
    (root / "features").mkdir(parents=True)
    (root / "errors.json").write_text(json.dumps({"codes": codes}), encoding="utf-8")
    for rel, body in features.items():
        path = root / "features" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body.strip() + "\n", encoding="utf-8")


def test_script_main_entrypoint_succeeds(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["validate_error_contracts.py"])
    runpy.run_path(str(SCRIPT_PATH), run_name="__main__")


def test_main_exits_when_catalog_has_no_codes(tmp_path, monkeypatch):
    module = load_module()
    _point_module_at_tmp(module, tmp_path, monkeypatch, codes=[], features={})
    with pytest.raises(SystemExit, match="no codes declared"):
        module.main()


def test_main_exits_on_undeclared_porto_code(tmp_path, monkeypatch):
    module = load_module()
    _point_module_at_tmp(
        module,
        tmp_path,
        monkeypatch,
        codes=[{"code": "PORTO_AUTH_FAILED"}],
        features={
            "sdk/core/errors.feature": ERROR_SCENARIO.format(
                scenario_id="core.unknown", code="PORTO_NOT_IN_CATALOG"
            )
        },
    )
    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_exits_on_duplicate_scenario_ids(tmp_path, monkeypatch):
    module = load_module()
    body = ERROR_SCENARIO.format(scenario_id="dup.id", code="PORTO_AUTH_FAILED")
    _point_module_at_tmp(
        module,
        tmp_path,
        monkeypatch,
        codes=[{"code": "PORTO_AUTH_FAILED"}],
        features={
            "sdk/core/errors.feature": body,
            "adapters/x/errors.feature": body,
        },
    )
    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_iter_error_scenarios_skips_document_without_feature(tmp_path, monkeypatch):
    module = load_module()

    class FakeParser:
        def parse(self, _content):
            return {}

    monkeypatch.setattr(module, "Parser", FakeParser)
    features_root = tmp_path / "features"
    features_root.mkdir()
    path = features_root / "x.feature"
    path.write_text("Feature: X\n", encoding="utf-8")
    assert module.iter_error_scenarios(path, features_root) == []


def test_iter_error_scenarios_collects_rule_scenarios(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    features_root.mkdir()
    path = features_root / "errors.feature"
    path.write_text(
        """
@sdk
Feature: R
  Rule: group
    @scenario:rule.err
    Scenario: inside rule
      Then I should get Porto error code "PORTO_AUTH_FAILED"
""".strip(),
        encoding="utf-8",
    )
    rows = module.iter_error_scenarios(path, features_root)
    assert len(rows) == 1
    assert rows[0]["scenario_id"] == "rule.err"


def test_extract_scenario_id_requires_tag():
    module = load_module()
    with pytest.raises(SystemExit, match="missing @scenario:"):
        module.extract_scenario_id(["@error"], "x.feature")


def test_extract_scenario_id_rejects_multiple_tags():
    module = load_module()
    with pytest.raises(SystemExit, match="multiple"):
        module.extract_scenario_id(["@scenario:a", "@scenario:b"], "x.feature")


def test_extract_porto_code_requires_one_code():
    module = load_module()
    with pytest.raises(SystemExit, match="missing PORTO_"):
        module.extract_porto_code([{"text": "Then fail"}], "id", "x.feature")
    with pytest.raises(SystemExit, match="multiple PORTO_"):
        module.extract_porto_code(
            [{"text": 'code "PORTO_A"'}, {"text": 'code "PORTO_B"'}],
            "id",
            "x.feature",
        )
