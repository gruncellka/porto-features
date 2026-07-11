import runpy
import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "generate_sdk_matrix.py"


def load_module():
    spec = spec_from_file_location("generate_sdk_matrix_module", SCRIPT_PATH)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_infer_slice_marks_outline_as_matrix():
    module = load_module()
    assert module._infer_slice("Any name", "Given x", "Scenario Outline") == "matrix"


def test_infer_slice_detects_invalid_input():
    module = load_module()
    assert (
        module._infer_slice("Reject letter with invalid dimensions", "Given x", "Scenario")
        == "invalid_input"
    )


def test_make_cell_id_deduplicates_collisions():
    module = load_module()
    used: set[str] = set()
    first = module._make_cell_id(
        "deutschepost", "pricing", "happy", "small", "domestic", "First", used
    )
    second = module._make_cell_id(
        "deutschepost", "pricing", "happy", "small", "domestic", "Second", used
    )
    assert first == "deutschepost.pricing.happy.small.domestic"
    assert second.startswith("deutschepost.pricing.happy.small.domestic.")


def test_generate_sdk_matrix_writes_cells(tmp_path):
    module = load_module()
    features_dir = tmp_path / "features"
    sdk_dir = features_dir / "sdk" / "providers" / "swisspost"
    sdk_dir.mkdir(parents=True)
    (sdk_dir / "resolution.feature").write_text(
        """
@sdk
@operator:swisspost
Feature: Swiss Post resolution
  Scenario: Resolve domestic A-Post standard letter
    Given provider is "swisspost"
    And I want to send a letter to country "CH"
    And the letter porto_id is "small"
    When I resolve the shipping configuration
    Then I should get product with id "a_post_standardbrief"
    And I should get zone with id "domestic"
""".strip(),
        encoding="utf-8",
    )

    output_path = tmp_path / "matrix" / "sdk.yaml"
    count = module.generate_sdk_matrix(features_dir, output_path)

    assert count == 1
    content = output_path.read_text(encoding="utf-8")
    assert "swisspost.resolution.happy.small.domestic" in content
    assert (
        "sdk/providers/swisspost/resolution.feature:Scenario:Resolve domestic A-Post standard letter"
        in content
    )


def test_script_main_entrypoint_exits_zero(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["generate_sdk_matrix.py"])
    with pytest.raises(SystemExit) as exc_info:
        runpy.run_path(str(SCRIPT_PATH), run_name="__main__")
    assert exc_info.value.code == 0


def test_generate_sdk_matrix_check_detects_drift(tmp_path):
    module = load_module()
    features_dir = tmp_path / "features" / "sdk" / "providers" / "swisspost"
    features_dir.mkdir(parents=True)
    (features_dir / "resolution.feature").write_text(
        """
@sdk
@operator:swisspost
Feature: Swiss Post resolution
  Scenario: Resolve domestic A-Post standard letter
    Given I want to send a letter to country "CH"
    When I resolve the shipping configuration
    Then I should get product with id "a_post_standardbrief"
""".strip(),
        encoding="utf-8",
    )
    output_path = tmp_path / "matrix" / "sdk.yaml"
    module.generate_sdk_matrix(features_dir.parents[1], output_path)
    output_path.write_text("stale\n", encoding="utf-8")

    expected = module._dump_sdk_yaml(module._scan_sdk_features(features_dir.parents[1]))
    actual = output_path.read_text(encoding="utf-8")
    assert actual != expected
