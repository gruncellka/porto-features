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


def test_collect_vocabulary_errors_flags_data_links_reference():
    module = load_module()
    errors = module._collect_vocabulary_errors('When I access "data_links.json"', Path("x.feature"))
    assert any("data_links.json" in e for e in errors)


def test_collect_tag_casing_errors_ignores_non_at_tags():
    module = load_module()
    feature = {
        "tags": [{"name": "not-a-tag"}],
        "children": [],
    }
    assert module._collect_tag_casing_errors(feature, Path("ok.feature")) == []


def test_collect_tag_casing_errors_rejects_uppercase_feature_tag():
    module = load_module()
    feature = {
        "tags": [{"name": "@SDK"}],
        "children": [{"scenario": {"name": "S", "tags": [], "steps": [{"text": "x"}]}}],
    }
    errors = module._collect_tag_casing_errors(feature, Path("bad.feature"))
    assert any("must be lowercase" in e and "@sdk" in e for e in errors)


def test_collect_tag_casing_errors_rejects_uppercase_scenario_tag():
    module = load_module()
    feature = {
        "tags": [{"name": "@adapters"}],
        "children": [
            {
                "scenario": {
                    "name": "Paid",
                    "tags": [{"name": "@Full"}],
                    "steps": [{"text": "x"}],
                }
            }
        ],
    }
    errors = module._collect_tag_casing_errors(feature, Path("bad.feature"))
    assert any("Scenario 'Paid'" in e and "@full" in e for e in errors)


def test_validate_layer_tags_errors_on_removed_release_tag():
    module = load_module()
    messages = module._validate_layer_tags({"adapters", "Release"}, Path("release.feature"))
    assert any("@release/@full are removed" in m for m in messages)


def test_validate_feature_file_rejects_uppercase_sdk_tag(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    feature_file = tmp_path / "upper.feature"
    feature_file.write_text(
        """
@SDK
Feature: Uppercase tag
  Scenario: One
    Given x
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("must be lowercase" in e for e in errors)


def test_collect_style_warnings_flags_implementation_tokens():
    module = load_module()
    content = "Given I have a Porto SDK client initialized"
    warnings = module._collect_style_warnings(content, Path("x.feature"))
    assert any("Porto SDK client" in w for w in warnings)
    assert not any("Non-canonical destination country" in w for w in warnings)


def test_collect_vocabulary_errors_flags_non_canonical_country():
    module = load_module()
    errors = module._collect_vocabulary_errors(
        'And destination country "DE"',
        Path("x.feature"),
    )
    assert any("Non-canonical destination country" in e for e in errors)


def test_collect_vocabulary_errors_flags_non_canonical_weight():
    module = load_module()
    errors = module._collect_vocabulary_errors("And weight 20 grams", Path("x.feature"))
    assert any("Non-canonical weight phrasing" in e for e in errors)


def test_collect_style_warnings_flags_class_names():
    module = load_module()
    warnings = module._collect_style_warnings("When PortoClient resolves", Path("x.feature"))
    assert any("PortoClient" in w for w in warnings)


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


def test_validate_layer_tags_rejects_both_sdk_and_adapters():
    module = load_module()
    messages = module._validate_layer_tags({"sdk", "adapters"}, Path("both.feature"))
    assert any("exactly one of @sdk or @adapters" in m for m in messages)


def test_validate_layer_tags_rejects_adapters_with_api():
    module = load_module()
    messages = module._validate_layer_tags({"adapters", "api"}, Path("api.feature"))
    assert any("Drop @api" in m for m in messages)


def test_validate_layer_tags_errors_on_removed_full_tag():
    module = load_module()
    messages = module._validate_layer_tags({"adapters", "full"}, Path("full.feature"))
    assert any("@release/@full are removed" in m and "use @heavy" in m for m in messages)


def test_load_module_exits_when_gherkin_missing(monkeypatch):
    load_fresh_module(monkeypatch, block="gherkin")


def test_load_module_continues_when_gherlint_missing(monkeypatch):
    module = load_fresh_module(monkeypatch, block="gherlint")
    assert module is not None
    assert module.gherlint is None


def test_validate_scope_tags_requires_provider_on_sdk_provider_path():
    module = load_module()
    path = Path("porto_features/features/sdk/providers/deutschepost/pricing.feature")
    errors = module._validate_scope_tags({"sdk"}, path)
    assert any("@core or exactly one @provider" in e for e in errors)


def test_validate_scope_tags_rejects_core_and_provider_together():
    module = load_module()
    path = Path("porto_features/features/sdk/core/restrictions.feature")
    errors = module._validate_scope_tags({"sdk", "core", "provider:deutschepost"}, path)
    assert any("mutually exclusive" in e for e in errors)


def test_validate_scope_tags_requires_wire_on_adapters():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/marks.feature")
    errors = module._validate_scope_tags({"adapters", "provider:deutschepost"}, path)
    assert any("@wire:" in e for e in errors)


def test_validate_scope_tags_skips_when_no_layer_tag_on_published_path():
    module = load_module()
    path = Path("porto_features/features/sdk/providers/deutschepost/pricing.feature")
    errors = module._validate_scope_tags({"core"}, path)
    assert errors == []


def test_validate_scope_tags_rejects_multiple_provider_tags_on_sdk():
    module = load_module()
    path = Path("porto_features/features/sdk/providers/deutschepost/pricing.feature")
    errors = module._validate_scope_tags(
        {"sdk", "provider:deutschepost", "provider:laposte"},
        path,
    )
    assert any("at most one @provider" in e for e in errors)


def test_validate_scope_tags_rejects_sdk_provider_path_mismatch():
    module = load_module()
    path = Path("porto_features/features/sdk/providers/laposte/pricing.feature")
    errors = module._validate_scope_tags({"sdk", "provider:deutschepost"}, path)
    assert any("must live under sdk/providers/deutschepost/" in e for e in errors)


def test_validate_scope_tags_rejects_core_outside_sdk_core():
    module = load_module()
    path = Path("porto_features/features/sdk/providers/deutschepost/pricing.feature")
    errors = module._validate_scope_tags({"sdk", "core"}, path)
    assert any("must live under sdk/core/" in e for e in errors)


def test_validate_scope_tags_rejects_adapters_without_provider():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/marks.feature")
    errors = module._validate_scope_tags({"adapters", "wire:internetmarke"}, path)
    assert any("exactly one @provider" in e for e in errors)


def test_validate_scope_tags_rejects_adapters_provider_path_mismatch():
    module = load_module()
    path = Path("porto_features/features/adapters/laposte/internetmarke/marks.feature")
    errors = module._validate_scope_tags(
        {"adapters", "provider:deutschepost", "wire:internetmarke"},
        path,
    )
    assert any("must live under adapters/deutschepost/" in e for e in errors)


def test_adapter_behavior_file_none_outside_adapters_tree():
    module = load_module()
    assert (
        module._adapter_behavior_file(Path("porto_features/features/sdk/core/errors.feature"))
        is None
    )


def test_adapter_behavior_file_none_for_other_adapter_filename():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/other.feature")
    assert module._adapter_behavior_file(path) is None


def test_validate_scope_tags_rejects_wire_directory_mismatch():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/marks.feature")
    errors = module._validate_scope_tags(
        {"adapters", "provider:deutschepost", "wire:wrongwire"},
        path,
    )
    assert any("@wire:wrongwire must match integration directory" in e for e in errors)


def test_validate_adapter_scenario_tags_requires_canary_or_heavy():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/marks.feature")
    scenarios = [{"scenario": {"name": "No lane", "tags": [], "steps": [{"text": "x"}]}}]
    errors = module._validate_adapter_scenario_tags({"adapters"}, scenarios, path)
    assert any("@canary or @heavy" in e for e in errors)


def test_validate_adapter_scenario_tags_accepts_canary():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/marks.feature")
    scenarios = [{"scenario": {"name": "Smoke", "tags": [{"name": "@canary"}], "steps": []}}]
    errors = module._validate_adapter_scenario_tags({"adapters"}, scenarios, path)
    assert errors == []


def test_validate_adapter_scenario_tags_accepts_error_on_errors_feature():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/errors.feature")
    scenarios = [{"scenario": {"name": "Auth fail", "tags": [{"name": "@error"}], "steps": []}}]
    errors = module._validate_adapter_scenario_tags({"adapters"}, scenarios, path)
    assert errors == []


def test_validate_adapter_scenario_tags_accepts_auth_on_errors_feature():
    module = load_module()
    path = Path("porto_features/features/adapters/deutschepost/internetmarke/errors.feature")
    scenarios = [
        {
            "scenario": {
                "name": "Auth boundary",
                "tags": [{"name": "@error"}, {"name": "@auth"}],
                "steps": [],
            }
        }
    ]
    errors = module._validate_adapter_scenario_tags({"adapters"}, scenarios, path)
    assert errors == []


def test_validate_feature_file_rejects_adapters_without_lane_tags(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    adapters_dir = (
        tmp_path / "porto_features" / "features" / "adapters" / "deutschepost" / "internetmarke"
    )
    adapters_dir.mkdir(parents=True)
    feature_file = adapters_dir / "marks.feature"
    feature_file.write_text(
        """
@adapters
@provider:deutschepost
@wire:internetmarke
Feature: Adapter
  Scenario: Untagged paid scenario
    Given x
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_feature_file(feature_file)
    assert not is_valid
    assert any("@canary or @heavy" in e for e in errors)


def test_iter_scenario_nodes_collects_rule_scenarios():
    module = load_module()
    content = """
Feature: R
  Rule: group
    Scenario: inside rule
      Given x
  Scenario: outside rule
    Given y
"""
    doc = module.Parser().parse(content)
    nodes = module._iter_scenario_nodes(doc["feature"])
    names = {n["scenario"]["name"] for n in nodes}
    assert names == {"inside rule", "outside rule"}


def test_script_main_entrypoint_exits_zero():
    with pytest.raises(SystemExit) as exc_info:
        runpy.run_path(str(SCRIPT_PATH), run_name="__main__")
    assert exc_info.value.code == 0
