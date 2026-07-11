# Changelog

## [Unreleased]

Internetmarke-first launch: SDK catalog depth for Deutsche Post, paid wire matrix via `adapters/deutschepost/internetmarke.feature`. Layout is multi-provider-ready; other adapters ship in later releases.

### Changed

- **BREAKING**: Feature layout under `porto_features/features/sdk/` (`@sdk`) and `porto_features/features/adapters/` (`@adapters`). SDK runners must discover `features/sdk/**/*.feature` and filter by `@sdk`.
- **BREAKING**: Provider-explicit paths: `sdk/core/`, `sdk/providers/{operator}/`, `adapters/{operator}/`. Matrix refs use nested paths (e.g. `sdk/providers/deutschepost/resolution.feature`, `adapters/deutschepost/internetmarke.feature`).
- **BREAKING**: Scope tags on every Feature: `@core` (cross-operator SDK) or `@operator:{id}` (operator catalog); adapters also require `@wire:{adapter}` (e.g. `@wire:internetmarke`).
- Tags renamed: `@offline` → `@sdk`, `@online`/`@api` → `@adapters`, `@release` → `@full`.
- **BREAKING**: Matrix generators moved to Porto SDK Lab (`scripts/matrix-sdk-sync.py`, `scripts/matrix-orders-sync.py`). Regenerate via `make matrix-sync` from Lab — not from this package.
- npm and PyPI packages ship `porto_features/matrix/*.{yaml,json}` (including `cases.generated.json` for TypeScript matrix parity).
- Gherkin **Rules** group related Backgrounds in `restrictions.feature`, `resolution.feature`, and multi-provider `cli.feature`.
- Letter validation split: address checks in `sdk/core/validation.feature`; Deutsche Post letter tiers in `sdk/providers/deutschepost/validation.feature`.
- `sdk/core/cli.feature`: `Rule: Core commands` plus per-operator Rules (`deutschepost`, `ukrposhta`, `laposte`, `swisspost`); SDK runners batch CLI BDD in bundle order.
- Ukrposhta `product_options.feature`: weight 500g for `large` / `dokument` domestic cell.
- `validate_features.py`: run gherlint from repo root so `gherlint.toml` config loads.
- CI: self-contained validation only (`make quality`, `make test-cov`) — no porto-data or Porto SDK Lab clones. Matrix generator drift gated in Lab CI.
- Publish packaging: `gherlint.toml` dev-only; hardened `MANIFEST.in` and `test_publish.sh` (clean wheel, forbidden-path guards).

### Added

- Matrix coverage index: `slices.yaml`, `sdk.yaml`, `canary.yaml`, `orders.generated.yaml` (Deutsche Post Internetmarke wire cells; synced from Lab), `cases.generated.json` (Lab-generated SDK case list for TS runners).
- Docs: `matrix.md`, `scenario-policy.md`, `vocabulary.md`.
- Doc naming rule: `.cursor/rules/doc-naming.mdc` (lowercase, no redirect stubs).
- Validator: matrix ref scenario/outline names, `sdk.yaml` slice taxonomy, scope-tag ↔ folder alignment.
- gherlint tag conventions in `pyproject.toml` (`@sdk`, `@operator:*`, `@wire:*`, `@canary`, `@full`).

### Removed

- `scripts/generate_sdk_matrix.py` — superseded by Porto SDK Lab `scripts/matrix-sdk-sync.py` and `labs/lib/matrix/`.
- Legacy doc redirect stubs: `docs/FEATURE_ANALYSIS.md`, `docs/STEP_VOCABULARY.md`, `docs/catalog-alignment.md`.

## [0.2.1]

### Changed

- Package metadata for PyPI/npm was expanded for better registry indexing and discoverability:
    - PyPI: explicit `license` file mapping, MIT classifier, project URLs, and changelog URL in `pyproject.toml`.
    - npm: added `author`, `homepage`, `bugs`, and included `CHANGELOG.md` in published `files`.
- `bump2version` auto-tagging is disabled (`tag = False`) to avoid creating tags from release branches; tags are now intended to be created manually on `main`.
- MIT `LICENSE` text was normalized to canonical ASCII quotes for tool/scanner compatibility.

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
