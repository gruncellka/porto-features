# Changelog

## [Unreleased]

### Removed

- **BREAKING**: Dropped `sdk/providers/deutschepost/mark_simulate.feature` (formerly `stamp_generation.feature`). It was a misnomer for resolve + `prepare_mark_order` and never created a PortoMark; coverage remains in `resolution.feature`.
- Dropped CLI scenarios `Simulate stamp generation` and `When I call CLI stamp simulate command...` (no CLI simulate command; steps faked `simulation: true`).
- **BREAKING**: Dropped CLI `When I call CLI restrictions command` scenarios (no public `restrict` CLI). Eligibility is `When I resolve the letter`.
- Dropped `When I check restrictions` / `When I check sanctions` as public steps.

### Changed

- **BREAKING**: Paid adapter matrix tag `@full` → `@heavy` (no alias). Historical: `@release` → `@full` → `@heavy`.
- `sdk/providers/deutschepost/api_comprehensive_testing.feature` → `pricing_matrix.feature`.
- **BREAKING**: Gherkin letter vocabulary — `When I resolve the letter`, `When I get the price`, `When I inspect … data`; no shipping/shipment; canary title `Purchase mark with pricing`.
- **BREAKING**: `restrictions.feature` goes through resolve (`PORTO_DESTINATION_UNSUPPORTED` for prohibited destinations/regions). Catalog inspect uses `When I inspect restrictions data`.
- Overweight and invalid-address errors use `When I resolve the letter` / `When I attempt to create a mark` (no envelope-type or prepare-mark-order harness).
- **BREAKING**: Service feature Then tokens use catalog feature `porto_id` — `tracking` (was `tracking_number`). Customer phrase “tracking number capability” stays.

## [0.4.0] - 2026-08-20

### Added

- **Jurisdiction address forms:** fixtures `invalid_postal_{DE,CH,FR,UA}`, `valid_postbox_{DE,UA}`; `valid_CH` uses 4-digit NPA; `sdk/core/validation.feature` outlines for DE/CH/FR/UA street + post-box success and postal-pattern failure; `details_schemas.PORTO_ADDRESS_INVALID` optional `field` / `reason` / `jurisdiction` / `form_issues` / `kind`.

### Changed

- **BREAKING**: Dropped `contracts/` — catalog is `porto_features/errors.json` (sibling of `features/`).
- **BREAKING**: Removed adapter `fixtures/adapters/**/errors.json` — Gherkin `@error` scenarios are enough.
- **BREAKING**: `@error` `@scenario:` ids must be unique across features (`make check`). Renamed adapter `core.letter.overweight` → `internetmarke.letter.overweight`.
- **BREAKING**: Removed `features.json` machine index — SDKs execute published Gherkin directly; no Gherkin→JSON copy.
- **BREAKING**: Removed `contracts/scenarios.json`. Error scenarios live in Gherkin (`@error` + `PORTO_*` steps) and must match `errors.json` (`make check-error-contracts`).
- **BREAKING**: Lab/CI matrix indexes moved out of this package to Porto SDK Lab `labs/matrix/` (no longer shipped on npm/PyPI).
- `docs/matrix.md` is a pointer to Lab matrix docs.
- Ukrposhta international CLI quote currency is **USD** (catalog world-zone price row), not UAH.

### Changed (prior unreleased)

- Added machine-readable error catalog under `porto_features/errors.json` (formerly `contracts/errors.json`).
- **BREAKING**: Adapter features live under `adapters/{operator}/{integration}/` with `marks.feature` (success) and `errors.feature` (failures). Matrix refs use `adapters/deutschepost/internetmarke/marks.feature:Outline:mark_order`.
- Added `@error`, `@auth`, and `@mark` scenario tags for adapter error contracts.
- **`@auth`**: auth/token/linkage failures on `errors.feature` (simulated OpenAPI 401 CI-safe; live DHL/Portokasse probes lab-only).

## [0.3.0] - 2026-07-11

Internetmarke-first launch: SDK catalog depth for Deutsche Post, paid wire matrix via `adapters/deutschepost/internetmarke.feature`. Layout is multi-provider-ready; other adapters ship in later releases.

### Changed

- **BREAKING**: Feature layout under `porto_features/features/sdk/` (`@sdk`) and `porto_features/features/adapters/` (`@adapters`). SDK runners must discover `features/sdk/**/*.feature` and filter by `@sdk`.
- **BREAKING**: Provider-explicit paths: `sdk/core/`, `sdk/providers/{operator}/`, `adapters/{operator}/`. Matrix refs use nested paths (e.g. `sdk/providers/deutschepost/resolution.feature`, `adapters/deutschepost/internetmarke.feature`); basename-only refs are rejected.
- **BREAKING**: Scope tags on every Feature: `@core` (cross-operator SDK) or `@operator:{id}` (operator catalog); adapters also require `@wire:{adapter}` (e.g. `@wire:internetmarke`).
- **BREAKING**: Tags renamed (all lowercase): `@offline` → `@sdk`, `@online`/`@api` → `@adapters`, `@release` → `@full`. Non-lowercase tags (e.g. `@SDK`, `@Full`) fail validation.
- **BREAKING**: Canonical Gherkin step phrasing enforced in validator — country, weight, and adapter `zone id` steps (see `docs/vocabulary.md`). SDK step defs must support canonical phrases; legacy aliases belong in implementor suites only.
- **BREAKING**: Matrix generators moved to Porto SDK Lab (`scripts/matrix-sdk-sync.py`, `scripts/matrix-orders-sync.py`). Regenerate via `make matrix-sync` from Lab — not from this package.
- npm and PyPI packages ship `porto_features/matrix/*.{yaml,json}` (including `cases.generated.json` for TypeScript matrix parity).
- Package description (README, PyPI, npm): **Structured BDD contracts for Porto SDK — shared Gherkin scenarios and JSON fixtures.**
- Gherkin **Rules** group related Backgrounds in `restrictions.feature`, `resolution.feature`, and multi-provider `cli.feature`.
- Letter validation split: address checks in `sdk/core/validation.feature`; Deutsche Post letter tiers in `sdk/providers/deutschepost/validation.feature`.
- `sdk/core/cli.feature`: `Rule: Core commands` plus per-operator Rules (`deutschepost`, `ukrposhta`, `laposte`, `swisspost`); SDK runners batch CLI BDD in bundle order.
- Ukrposhta `product_options.feature`: weight 500g for `large` / `dokument` domestic cell.
- `validate_features.py`: run gherlint from repo root so `gherlint.toml` config loads; matrix ref, vocabulary, scope-tag, adapter-lane, and tag-casing checks.
- CI: self-contained validation only (`make quality`, `make test-cov`) — no porto-data or Porto SDK Lab clones. Matrix generator drift gated in Lab CI.
- Publish packaging: `gherlint.toml` dev-only; hardened `MANIFEST.in` and `test_publish.sh` (clean wheel, forbidden-path guards).
- **License:** Apache-2.0 — PEP 639 `license = "Apache-2.0"` + `license-files` (removed `License :: OSI Approved :: MIT License` classifier); npm `Apache-2.0`.

### Added

- Matrix coverage index: `slices.yaml`, `sdk.yaml`, `canary.yaml`, `orders.generated.yaml` (Deutsche Post Internetmarke wire cells; synced from Lab), `cases.generated.json` (Lab-generated SDK case list for TS runners).
- Docs: `matrix.md`, `scenario-policy.md`, `vocabulary.md` (tag casing, deprecated tag renames, canonical steps).
- Doc naming rule: `.cursor/rules/doc-naming.mdc` (lowercase, no redirect stubs).
- Validator: matrix ref scenario/outline names, `sdk.yaml` slice taxonomy, scope-tag ↔ folder alignment, `@adapters` requires scenario `@canary` or `@full`.
- `gherlint.toml` tag patterns: `@sdk`, `@adapters`, `@core`, `@operator:*`, `@wire:*`, `@canary`, `@full`.

### Removed

- `scripts/generate_sdk_matrix.py` — superseded by Porto SDK Lab `scripts/matrix-sdk-sync.py` and `labs/lib/matrix/`.
- Legacy root docs superseded by `docs/`: `BDD_POLICY.md`, `FEATURE_ANALYSIS.md`, `STEP_VOCABULARY.md`.
- Address fixtures `valid_GB.json` and `valid_NO.json` (no scenarios reference them — `valid_NO` may return when Norway coverage ships).

## [0.2.1] - 2026-03-12

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
