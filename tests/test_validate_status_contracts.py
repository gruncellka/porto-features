import json
import runpy
import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "validate_status_contracts.py"

STATUS_SCENARIO = """
@sdk
Feature: Status
  @scenario:{scenario_id}
  Scenario: Status scenario
    Then "{code}" should be declared in the PortoStatus catalog
""".strip()


def load_module():
    spec = spec_from_file_location("validate_status_contracts_module", SCRIPT_PATH)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_iter_status_scenarios_requires_code(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    status_dir = features_root / "sdk" / "core"
    status_dir.mkdir(parents=True)
    (status_dir / "status.feature").write_text(
        """
@sdk
@core
Feature: PortoStatus catalog contract
  @scenario:core.status.catalog_includes_created
  Scenario: created is declared in the PortoStatus catalog
    Then "created" should be declared in the PortoStatus catalog
""".strip(),
        encoding="utf-8",
    )

    rows = module.iter_status_scenarios(status_dir / "status.feature", features_root)
    assert len(rows) == 1
    assert rows[0]["scenario_id"] == "core.status.catalog_includes_created"
    assert rows[0]["status_code"] == "created"
    assert "@status" in rows[0]["tags"]


def test_non_status_feature_yields_no_rows(tmp_path):
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

    rows = module.iter_status_scenarios(
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
  @status
  @scenario:dup.id
  Scenario: One
    Then "created" should be declared in the PortoStatus catalog
""".strip()
    (a / "status.feature").write_text(feature_body, encoding="utf-8")
    (b / "other.feature").write_text(feature_body, encoding="utf-8")

    seen: dict[str, str] = {}
    problems: list[str] = []
    for feature_path in sorted(features_root.rglob("*.feature")):
        for row in module.iter_status_scenarios(feature_path, features_root):
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
    monkeypatch.setattr(module, "__file__", str(scripts / "validate_status_contracts.py"))
    monkeypatch.setattr(sys, "argv", ["validate_status_contracts.py"])
    root = tmp_path / "porto_features"
    (root / "features").mkdir(parents=True)
    (root / "statuses.json").write_text(json.dumps({"codes": codes}), encoding="utf-8")
    for rel, body in features.items():
        path = root / "features" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body.strip() + "\n", encoding="utf-8")


def test_script_main_entrypoint_succeeds(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["validate_status_contracts.py"])
    runpy.run_path(str(SCRIPT_PATH), run_name="__main__")


def test_main_exits_when_catalog_has_no_codes(tmp_path, monkeypatch):
    module = load_module()
    _point_module_at_tmp(module, tmp_path, monkeypatch, codes=[], features={})
    with pytest.raises(SystemExit, match="no codes declared"):
        module.main()


def test_main_exits_on_undeclared_status_code(tmp_path, monkeypatch):
    module = load_module()
    _point_module_at_tmp(
        module,
        tmp_path,
        monkeypatch,
        codes=[{"code": "created", "domain": "tracking", "description": "Recorded."}],
        features={
            "sdk/core/status.feature": STATUS_SCENARIO.format(
                scenario_id="core.unknown", code="not_a_status"
            )
        },
    )
    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_exits_on_duplicate_scenario_ids(tmp_path, monkeypatch):
    module = load_module()
    body = STATUS_SCENARIO.format(scenario_id="dup.id", code="created")
    _point_module_at_tmp(
        module,
        tmp_path,
        monkeypatch,
        codes=[{"code": "created", "domain": "tracking", "description": "Recorded."}],
        features={
            "sdk/core/status.feature": body,
            "adapters/x/status.feature": body,
        },
    )
    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_catalog_rejects_bad_rows(tmp_path):
    module = load_module()
    path = tmp_path / "statuses.json"
    with pytest.raises(SystemExit, match="must be an object"):
        module.catalog_codes({"codes": ["created"]}, path)
    with pytest.raises(SystemExit, match="missing code"):
        module.catalog_codes({"codes": [{"code": "created"}]}, path)
    with pytest.raises(SystemExit, match="duplicate"):
        module.catalog_codes(
            {
                "codes": [
                    {"code": "created", "domain": "tracking", "description": "A"},
                    {"code": "created", "domain": "tracking", "description": "B"},
                ]
            },
            path,
        )


def test_iter_status_scenarios_skips_document_without_feature(tmp_path, monkeypatch):
    module = load_module()

    class FakeParser:
        def parse(self, _content):
            return {}

    monkeypatch.setattr(module, "Parser", FakeParser)
    features_root = tmp_path / "features"
    features_root.mkdir()
    path = features_root / "x.feature"
    path.write_text("Feature: X\n", encoding="utf-8")
    assert module.iter_status_scenarios(path, features_root) == []


def test_iter_status_scenarios_collects_rule_scenarios(tmp_path):
    module = load_module()
    features_root = tmp_path / "features"
    features_root.mkdir()
    path = features_root / "status.feature"
    path.write_text(
        """
@sdk
Feature: R
  Rule: group
    @scenario:rule.status
    Scenario: inside rule
      Then "created" should be declared in the PortoStatus catalog
""".strip(),
        encoding="utf-8",
    )
    rows = module.iter_status_scenarios(path, features_root)
    assert len(rows) == 1
    assert rows[0]["scenario_id"] == "rule.status"


def test_extract_scenario_id_requires_tag():
    module = load_module()
    with pytest.raises(SystemExit, match="missing @scenario:"):
        module.extract_scenario_id(["@status"], "x.feature")


def test_extract_scenario_id_rejects_multiple_tags():
    module = load_module()
    with pytest.raises(SystemExit, match="multiple"):
        module.extract_scenario_id(["@scenario:a", "@scenario:b"], "x.feature")


def test_catalog_codes_rejects_shipment_word(tmp_path):
    module = load_module()
    path = tmp_path / "statuses.json"
    with pytest.raises(SystemExit, match="forbidden word"):
        module.catalog_codes(
            {
                "codes": [
                    {
                        "code": "created",
                        "domain": "tracking",
                        "description": "Shipment recorded",
                    }
                ]
            },
            path,
        )


def test_extract_status_code_requires_one_code():
    module = load_module()
    with pytest.raises(SystemExit, match="missing quoted"):
        module.extract_status_code([{"text": "Then fail"}], "id", "x.feature")
    with pytest.raises(SystemExit, match="multiple status"):
        module.extract_status_code(
            [{"text": '"created"'}, {"text": '"delivered"'}],
            "id",
            "x.feature",
        )
