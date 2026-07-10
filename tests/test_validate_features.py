import builtins
import runpy
import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "validate_features.py"


def load_module():
    spec = spec_from_file_location("validate_features_module", SCRIPT_PATH)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def load_fresh_module(monkeypatch, *, block: str | None = None):
    module_name = f"validate_features_fresh_{block or 'full'}"
    monkeypatch.delitem(sys.modules, module_name, raising=False)
    real_import = builtins.__import__

    def guarded_import(name, globals=None, locals=None, fromlist=(), level=0):
        if block == "gherkin" and (name == "gherkin" or name.startswith("gherkin.")):
            raise ImportError("blocked gherkin")
        if block == "gherlint" and name == "gherlint":
            raise ImportError("blocked gherlint")
        if block == "yaml" and name == "yaml":
            raise ImportError("blocked yaml")
        return real_import(name, globals, locals, fromlist, level)

    if block:
        monkeypatch.setattr(builtins, "__import__", guarded_import)

    spec = spec_from_file_location(module_name, SCRIPT_PATH)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    if block == "gherkin":
        with pytest.raises(SystemExit) as exc_info:
            spec.loader.exec_module(module)
        assert exc_info.value.code == 1
        return None

    spec.loader.exec_module(module)
    return module


def test_find_feature_files_returns_sorted_feature_files(tmp_path):
    module = load_module()
    features_dir = tmp_path / "features"
    features_dir.mkdir()
    (features_dir / "b.feature").write_text("Feature: B\nScenario: S\n Given x\n", encoding="utf-8")
    (features_dir / "a.feature").write_text("Feature: A\nScenario: S\n Given x\n", encoding="utf-8")
    (features_dir / "ignore.txt").write_text("x", encoding="utf-8")

    files = module.find_feature_files(features_dir)
    assert [f.name for f in files] == ["a.feature", "b.feature"]


def test_validate_feature_file_rejects_missing_execution_tag(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "untagged.feature"
    feature_file.write_text(
        """
Feature: Untagged
  Scenario: No tag
    Given x
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("@sdk or @adapters" in e for e in errors)


def test_validate_feature_file_rejects_legacy_product_id(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "legacy.feature"
    feature_file.write_text(
        """
@sdk
Feature: Legacy
  Scenario: Old id
    Given product "letter_standard"
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("letter_standard" in e for e in errors)


def test_validate_feature_file_rejects_legacy_letter_type_enum(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "enum.feature"
    feature_file.write_text(
        """
@sdk
Feature: Enum
  Scenario: Old enum
    Given the letter type is "STANDARD"
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("STANDARD" in e for e in errors)


def test_collect_vocabulary_errors_flags_data_links_reference():
    module = load_module()
    errors = module._collect_vocabulary_errors('When I access "data_links.json"', Path("x.feature"))
    assert any("data_links.json" in e for e in errors)


def test_feature_tags_extracts_sdk_tag():
    module = load_module()
    tags = module._feature_tags({"tags": [{"name": "@sdk"}, {"name": "@slow"}]})
    assert "sdk" in tags


def test_validate_feature_file_accepts_valid_feature(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "ok.feature"
    feature_file.write_text(
        """
@sdk
Feature: Validation
  Scenario: Valid scenario
    Given I have input
    When I run validation
    Then it should pass
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert is_valid
    assert errors == []


def test_validate_feature_file_rejects_missing_scenarios(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "no_scenarios.feature"
    feature_file.write_text("Feature: No scenarios", encoding="utf-8")

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("has no scenarios" in e for e in errors)


def test_validate_feature_file_warns_on_duplicate_scenario_names(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "dup.feature"
    feature_file.write_text(
        """
@sdk
Feature: Duplicate names
  Scenario: Same name
    Given one
    Then one

  Scenario: Same name
    Given two
    Then two
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert is_valid
    assert any("Duplicate scenario names" in e for e in errors)


def test_validate_feature_file_reports_missing_feature_declaration(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "missing_feature.feature"
    feature_file.write_text("Feature: Placeholder", encoding="utf-8")

    class FakeParser:
        def parse(self, _content):
            return {}

    module.Parser = FakeParser
    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("Missing Feature declaration" in e for e in errors)


def test_validate_feature_file_reports_scenario_with_no_steps(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "no_steps.feature"
    feature_file.write_text(
        """
@sdk
Feature: No steps
  Scenario: No steps
""".strip(),
        encoding="utf-8",
    )
    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("has no steps" in e for e in errors)


def test_validate_feature_file_returns_parse_error_for_broken_gherkin(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "broken.feature"
    feature_file.write_text("Scenario: no feature header", encoding="utf-8")

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("Parse error" in e or "Error -" in e for e in errors)


def test_validate_feature_file_handles_non_parse_exception(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "broken.feature"
    feature_file.write_text("Feature: x", encoding="utf-8")

    class FakeParser:
        def parse(self, _content):
            raise RuntimeError("boom")

    module.Parser = FakeParser
    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("Error - boom" in e for e in errors)


def test_find_feature_files_returns_empty_when_directory_missing(tmp_path):
    module = load_module()
    files = module.find_feature_files(tmp_path / "does-not-exist")
    assert files == []


def test_run_gherlint_success(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", object())

    class Result:
        returncode = 0
        stdout = ""
        stderr = ""

    monkeypatch.setattr(module.subprocess, "run", lambda *args, **kwargs: Result())

    valid, errors = module.run_gherlint(tmp_path)
    assert valid
    assert errors == []


def test_run_gherlint_success_with_hints_returns_warnings(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", object())

    class Result:
        returncode = 0
        stdout = (
            "porto_features/features/x.feature:1:1: "
            "Scenario does not contain any Given step (missing-given-step)"
        )
        stderr = ""

    monkeypatch.setattr(module.subprocess, "run", lambda *args, **kwargs: Result())

    valid, errors = module.run_gherlint(tmp_path)
    assert valid
    assert any("Gherkin linting hints" in e for e in errors)


def test_run_gherlint_failure_returns_errors(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", object())

    class Result:
        returncode = 1
        stdout = "lint error"
        stderr = ""

    monkeypatch.setattr(module.subprocess, "run", lambda *args, **kwargs: Result())

    valid, errors = module.run_gherlint(tmp_path)
    assert not valid
    assert any("Gherkin linting errors" in e for e in errors)


def test_run_gherlint_skips_when_python_module_unavailable(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", None)
    valid, errors = module.run_gherlint(tmp_path)
    assert valid
    assert errors == []


def test_run_gherlint_handles_missing_binary(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", object())

    def raise_not_found(*args, **kwargs):
        raise FileNotFoundError

    monkeypatch.setattr(module.subprocess, "run", raise_not_found)
    valid, errors = module.run_gherlint(tmp_path)
    assert valid
    assert any("command not found" in e for e in errors)


def test_run_gherlint_handles_generic_exception(monkeypatch, tmp_path):
    module = load_module()
    monkeypatch.setattr(module, "gherlint", object())

    def raise_runtime_error(*args, **kwargs):
        raise RuntimeError("unexpected")

    monkeypatch.setattr(module.subprocess, "run", raise_runtime_error)
    valid, errors = module.run_gherlint(tmp_path)
    assert valid
    assert any("Error running gherlint" in e for e in errors)


def test_find_feature_files_finds_nested_features(tmp_path):
    module = load_module()
    features_dir = tmp_path / "features"
    sdk_dir = features_dir / "sdk"
    sdk_dir.mkdir(parents=True)
    (sdk_dir / "nested.feature").write_text("Feature: N\nScenario: S\n Given x\n", encoding="utf-8")

    files = module.find_feature_files(features_dir)
    assert [f.name for f in files] == ["nested.feature"]


def test_validate_matrix_files_rejects_mismatched_case_id(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    matrix_dir.mkdir()
    features_dir.mkdir()
    (matrix_dir / "slices.yaml").write_text("schema_version: 1\n", encoding="utf-8")
    (matrix_dir / "sdk.yaml").write_text("schema_version: 1\nsdk_cells: []\n", encoding="utf-8")
    (matrix_dir / "canary.yaml").write_text("schema_version: 1\ncase_ids: []\n", encoding="utf-8")
    (matrix_dir / "orders.generated.yaml").write_text(
        """
schema_version: 1
order_cells:
  - case_id: wrong_slug
    provider: deutschepost
    adapter: internetmarke
    product_id: standardbrief
    zone_id: domestic
    service_ids: []
    refs: []
""".strip(),
        encoding="utf-8",
    )

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    assert not ok
    assert any("does not match structured fields" in e for e in errors)


def test_validate_matrix_files_rejects_canary_not_in_orders(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    matrix_dir.mkdir()
    features_dir.mkdir()
    (matrix_dir / "slices.yaml").write_text("schema_version: 1\n", encoding="utf-8")
    (matrix_dir / "sdk.yaml").write_text("schema_version: 1\nsdk_cells: []\n", encoding="utf-8")
    (matrix_dir / "orders.generated.yaml").write_text(
        "schema_version: 1\norder_cells: []\n", encoding="utf-8"
    )
    (matrix_dir / "canary.yaml").write_text(
        "schema_version: 1\ncase_ids:\n  - missing_case\n", encoding="utf-8"
    )

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    assert not ok
    assert any("missing_case" in e for e in errors)


def test_main_exits_1_when_no_feature_files(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [])

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_exits_1_when_feature_has_errors(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [Path("x.feature")])
    monkeypatch.setattr(module, "validate_feature_file", lambda _p: (False, ["❌ bad"]))
    monkeypatch.setattr(module, "run_gherlint", lambda _d: (True, []))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_exits_1_when_lint_has_errors(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [Path("x.feature")])
    monkeypatch.setattr(module, "validate_feature_file", lambda _p: (True, []))
    monkeypatch.setattr(module, "run_gherlint", lambda _d: (False, ["❌ lint bad"]))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_handles_warnings_but_exits_0(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [Path("x.feature")])
    monkeypatch.setattr(
        module, "validate_feature_file", lambda _p: (True, ["⚠️ duplicate scenario names"])
    )
    monkeypatch.setattr(module, "run_gherlint", lambda _d: (True, ["⚠️ lint warning"]))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 0


def test_main_exits_0_when_all_feature_checks_pass(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [Path("x.feature")])
    monkeypatch.setattr(module, "validate_feature_file", lambda _p: (True, []))
    monkeypatch.setattr(module, "run_gherlint", lambda _d: (True, []))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 0


def test_main_exits_1_when_matrix_has_errors(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_feature_files", lambda _d: [Path("x.feature")])
    monkeypatch.setattr(module, "validate_feature_file", lambda _p: (True, []))
    monkeypatch.setattr(
        module, "validate_matrix_files", lambda _m, _f: (False, ["❌ matrix bad"])
    )
    monkeypatch.setattr(module, "run_gherlint", lambda _d: (True, []))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_ref_feature_path_appends_extension_for_bare_name():
    module = load_module()
    assert module._ref_feature_path("resolution:Scenario:Name") == "resolution.feature"


def test_ref_feature_path_keeps_nested_path():
    module = load_module()
    assert module._ref_feature_path("sdk/resolution:Scenario:Name") == "sdk/resolution.feature"


def test_expected_case_id_includes_service_ids():
    module = load_module()
    cell = {
        "provider": "deutschepost",
        "adapter": "internetmarke",
        "product_id": "standardbrief",
        "zone_id": "domestic",
        "service_ids": ["einschreiben"],
    }
    assert module._expected_case_id(cell) == (
        "deutschepost.internetmarke.standardbrief.domestic.einschreiben"
    )


def test_collect_vocabulary_errors_flags_deprecated_service_id():
    module = load_module()
    errors = module._collect_vocabulary_errors('Given service "registered_mail"', Path("x.feature"))
    assert any("registered_mail" in e for e in errors)


def test_validate_layer_tags_warns_on_deprecated_offline_tag():
    module = load_module()
    messages = module._validate_layer_tags({"offline"}, Path("legacy.feature"))
    assert any("Deprecated tag" in m and "offline" in m for m in messages)


def test_validate_layer_tags_rejects_both_sdk_and_adapters():
    module = load_module()
    messages = module._validate_layer_tags({"sdk", "adapters"}, Path("both.feature"))
    assert any("exactly one of @sdk or @adapters" in m for m in messages)


def test_validate_layer_tags_rejects_adapters_with_api():
    module = load_module()
    messages = module._validate_layer_tags({"adapters", "api"}, Path("api.feature"))
    assert any("Drop @api" in m for m in messages)


def test_validate_layer_tags_warns_on_deprecated_release_tag():
    module = load_module()
    messages = module._validate_layer_tags({"adapters", "release"}, Path("release.feature"))
    assert any("@release is deprecated" in m for m in messages)


def test_validate_matrix_files_skips_when_yaml_unavailable(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "yaml", None)
    ok, errors = module.validate_matrix_files(tmp_path / "matrix", tmp_path / "features")
    assert ok
    assert errors == []


def test_validate_matrix_files_rejects_missing_matrix_files(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    matrix_dir.mkdir()

    ok, errors = module.validate_matrix_files(matrix_dir, tmp_path / "features")
    assert not ok
    assert any("Missing matrix file" in e for e in errors)


def _write_minimal_matrix_files(matrix_dir: Path) -> None:
    (matrix_dir / "slices.yaml").write_text("schema_version: 1\n", encoding="utf-8")
    (matrix_dir / "sdk.yaml").write_text("schema_version: 1\nsdk_cells: []\n", encoding="utf-8")
    (matrix_dir / "canary.yaml").write_text("schema_version: 1\ncase_ids: []\n", encoding="utf-8")
    (matrix_dir / "orders.generated.yaml").write_text(
        "schema_version: 1\norder_cells: []\n", encoding="utf-8"
    )


def test_validate_matrix_files_rejects_missing_sdk_ref(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    matrix_dir.mkdir()
    features_dir.mkdir()
    _write_minimal_matrix_files(matrix_dir)
    (matrix_dir / "sdk.yaml").write_text(
        """
schema_version: 1
sdk_cells:
  - refs:
      - sdk/missing.feature:Scenario:Name
""".strip(),
        encoding="utf-8",
    )

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    assert not ok
    assert any("sdk.yaml: ref" in e and "feature file not found" in e for e in errors)


def test_validate_matrix_files_accepts_sdk_ref_via_sdk_subdir(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    sdk_dir = features_dir / "sdk"
    matrix_dir.mkdir()
    sdk_dir.mkdir(parents=True)
    (sdk_dir / "resolution.feature").write_text(
        "Feature: R\nScenario: S\n Given x\n", encoding="utf-8"
    )
    _write_minimal_matrix_files(matrix_dir)
    (matrix_dir / "sdk.yaml").write_text(
        """
schema_version: 1
sdk_cells:
  - refs:
      - resolution:Scenario:Name
""".strip(),
        encoding="utf-8",
    )

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    assert ok
    assert errors == []


def test_validate_matrix_files_rejects_missing_order_ref(tmp_path):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    matrix_dir.mkdir()
    features_dir.mkdir()
    _write_minimal_matrix_files(matrix_dir)
    (matrix_dir / "orders.generated.yaml").write_text(
        """
schema_version: 1
order_cells:
  - case_id: deutschepost.internetmarke.standardbrief.domestic
    provider: deutschepost
    adapter: internetmarke
    product_id: standardbrief
    zone_id: domestic
    service_ids: []
    refs:
      - adapters/missing.feature:Scenario:Name
""".strip(),
        encoding="utf-8",
    )

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    assert not ok
    assert any("feature file not found" in e for e in errors)


def test_validate_matrix_files_reports_success_summary(tmp_path, capsys):
    module = load_module()
    matrix_dir = tmp_path / "matrix"
    features_dir = tmp_path / "features"
    matrix_dir.mkdir()
    features_dir.mkdir()
    _write_minimal_matrix_files(matrix_dir)

    ok, errors = module.validate_matrix_files(matrix_dir, features_dir)
    captured = capsys.readouterr()

    assert ok
    assert errors == []
    assert "order_cells" in captured.out


def test_load_module_exits_when_gherkin_missing(monkeypatch):
    load_fresh_module(monkeypatch, block="gherkin")


def test_load_module_continues_when_gherlint_missing(monkeypatch):
    module = load_fresh_module(monkeypatch, block="gherlint")
    assert module is not None
    assert module.gherlint is None


def test_load_module_continues_when_yaml_missing(monkeypatch):
    module = load_fresh_module(monkeypatch, block="yaml")
    assert module is not None
    assert module.yaml is None


def test_script_main_entrypoint_exits_zero():
    with pytest.raises(SystemExit) as exc_info:
        runpy.run_path(str(SCRIPT_PATH), run_name="__main__")
    assert exc_info.value.code == 0
