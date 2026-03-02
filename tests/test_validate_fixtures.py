from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest


def load_module():
    script_path = (
        Path(__file__).resolve().parents[1] / "scripts" / "validate_fixtures.py"
    )
    spec = spec_from_file_location("validate_fixtures_module", script_path)
    module = module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_find_fixture_files_returns_sorted_json_files(tmp_path):
    module = load_module()
    fixtures_dir = tmp_path / "fixtures"
    fixtures_dir.mkdir()
    (fixtures_dir / "b.json").write_text("{}", encoding="utf-8")
    (fixtures_dir / "a.json").write_text("{}", encoding="utf-8")
    (fixtures_dir / "ignore.txt").write_text("x", encoding="utf-8")

    files = module.find_fixture_files(fixtures_dir)
    assert [f.name for f in files] == ["a.json", "b.json"]


def test_validate_address_fixture_reports_missing_required_field(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    address_file = tmp_path / "porto_features" / "fixtures" / "addresses" / "x.json"
    address_file.parent.mkdir(parents=True)
    address_file.write_text("{}", encoding="utf-8")

    errors = module.validate_address_fixture(
        address_file,
        {
            "id": "addr",
            "name": "Name",
            "street": "Main",
            "house_number": "1",
            "postal_code": "12345",
            "city": "City",
        },
    )
    assert any("country_code" in e for e in errors)


def test_validate_address_fixture_rejects_empty_region_code(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    address_file = tmp_path / "porto_features" / "fixtures" / "addresses" / "x.json"
    address_file.parent.mkdir(parents=True)
    address_file.write_text("{}", encoding="utf-8")

    errors = module.validate_address_fixture(
        address_file,
        {
            "id": "addr",
            "name": "Name",
            "street": "Main",
            "house_number": "1",
            "postal_code": "12345",
            "city": "City",
            "country_code": "DE",
            "region_code": " ",
        },
    )
    assert any("region_code" in e for e in errors)


def test_find_fixture_files_returns_empty_when_directory_missing(tmp_path):
    module = load_module()
    files = module.find_fixture_files(tmp_path / "does-not-exist")
    assert files == []


def test_validate_address_fixture_rejects_empty_required_string(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    address_file = tmp_path / "porto_features" / "fixtures" / "addresses" / "x.json"
    address_file.parent.mkdir(parents=True)
    address_file.write_text("{}", encoding="utf-8")

    errors = module.validate_address_fixture(
        address_file,
        {
            "id": "addr",
            "name": "",
            "street": "Main",
            "house_number": "1",
            "postal_code": "12345",
            "city": "City",
            "country_code": "DE",
        },
    )
    assert any("must be a non-empty string" in e for e in errors)


def test_validate_fixture_file_rejects_invalid_json(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    fixture_file = tmp_path / "bad.json"
    fixture_file.write_text("{ bad", encoding="utf-8")

    is_valid, errors = module.validate_fixture_file(fixture_file)
    assert not is_valid
    assert any("Invalid JSON" in e for e in errors)


def test_validate_fixture_file_requires_object_root(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    fixture_file = tmp_path / "list.json"
    fixture_file.write_text("[]", encoding="utf-8")

    is_valid, errors = module.validate_fixture_file(fixture_file)
    assert not is_valid
    assert any("Root must be a JSON object" in e for e in errors)


def test_validate_fixture_file_accepts_valid_address(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    fixture_file = tmp_path / "porto_features" / "fixtures" / "addresses" / "valid_DE.json"
    fixture_file.parent.mkdir(parents=True)
    fixture_file.write_text(
        """
{
  "id": "addr_de_berlin",
  "name": "Test Empfaenger",
  "street": "Friedrichstrasse",
  "house_number": "123",
  "postal_code": "10117",
  "city": "Berlin",
  "region_code": "DE-BE",
  "country_code": "DE"
}
""".strip(),
        encoding="utf-8",
    )

    is_valid, errors = module.validate_fixture_file(fixture_file)
    assert is_valid
    assert errors == []


def test_validate_fixture_file_fails_when_address_errors_exist(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.chdir(tmp_path)
    fixture_file = tmp_path / "porto_features" / "fixtures" / "addresses" / "invalid.json"
    fixture_file.parent.mkdir(parents=True)
    fixture_file.write_text('{"id": "x"}', encoding="utf-8")

    is_valid, errors = module.validate_fixture_file(fixture_file)
    assert not is_valid
    assert errors


def test_main_exits_1_when_no_fixtures(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_fixture_files", lambda _d: [])

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_exits_1_when_fixture_invalid(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_fixture_files", lambda _d: [Path("x.json")])
    monkeypatch.setattr(module, "validate_fixture_file", lambda _p: (False, ["err"]))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 1


def test_main_handles_warnings_but_exits_0(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_fixture_files", lambda _d: [Path("x.json")])
    monkeypatch.setattr(module, "validate_fixture_file", lambda _p: (False, ["⚠️ warning"]))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 0


def test_main_exits_0_when_all_fixtures_valid(monkeypatch):
    module = load_module()
    monkeypatch.setattr(module, "find_fixture_files", lambda _d: [Path("x.json")])
    monkeypatch.setattr(module, "validate_fixture_file", lambda _p: (True, []))

    with pytest.raises(SystemExit) as exc_info:
        module.main()
    assert exc_info.value.code == 0
