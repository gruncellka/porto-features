# Changelog

## [0.2.0] - 2026-03-06

### Changed

- **BREAKING**: Python baseline is now **3.13+** (`requires-python >=3.13`).
- **Tooling**: Ruff/MyPy targets are aligned to Python **3.13**.
- **npm runtime**: minimum Node.js is now **>=20** via `engines.node`.
- **TypeScript**: development/build baseline is now pinned to **5.9.x** (`~5.9.3`).
- **Setup reliability**: `make setup` now detects Git repos/submodules correctly for hook installation.

## [0.1.0] - 2026-03-02

Initial public release.

### Added

- Shared Gherkin feature set under `porto_features/features`.
- Shared JSON fixtures under `porto_features/fixtures`.
- Validation scripts for features and fixtures.
- npm + PyPI packaging configuration.
- npm entrypoint and TypeScript declarations (`index.js`, `index.d.ts`).
- CI workflows for validation and publishing.
- Pre-publish package verification script (`tests/test_publish.sh`).

### Notes

- This is the baseline release for future diffs.
