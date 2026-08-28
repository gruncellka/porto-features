# Changelog

## [Unreleased]

### Removed

- **BREAKING — errors.json:** drop `PORTO_DESTINATION_RESTRICTED` (unreachable; `resolve()` attaches restrictions as data and does not fail closed).

### Changed

- **CI / tooling:** validation workflow uses short parallel leaf jobs (`features`, `fixtures`, `errors`, `format`, `lint`, `types`, `test`) with aggregator `validate`; pre-commit hook names aligned; removed `make check`, `make quality`, and `make test-cov` aliases; `make format` is check-only (rewrite via pre-commit); coverage gate 100% in `pyproject.toml`; concurrency group `${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}` (avoids push/PR cancel).
- **BREAKING — errors.json:** drop `PORTO_MARKS_MISMATCH` and `PORTO_MARKS_MANY_UNSUPPORTED` (not provider facts; Internetmarke executes any list; provider reject → `PORTO_MARK_FAILED`). Remove `internetmarke.mark.many_*` Gherkin that asserted those codes.
- **restrictions.feature:** `resolve()` attaches country-level `Restrictions` (`impact` + `items[]`). Region precision is `restrictions.check(country, region)` only. Country aggregate is `warn` when any regional facts exist (never promote child `block`). Kherson `UA-65` is the primary partial example. Exact full legal → `block`; unaffected region → `impact: null`. Legal applicability is provider-jurisdiction driven (`legal jurisdictions` steps); routing is destination-only. `resolve` does not fail closed.
- **mark together:** Internetmarke executes heterogeneous lists; core keeps empty-list + capture-loop success. Paid 3-packs assert one shared external id. Batch grouping is a consumer concern.
- **Address fixtures / validation Gherkin:** `city` → `locality` (UPU postal vocabulary; matches porto-data address forms).
- **Internetmarke `errors.feature`:** wallet insufficient and invalid DHL/Portokasse auth scenarios use deterministic mark-execution HTTP mapping triggers (no live purchase / no empty-wallet dependency). Invalid DHL app maps to `PORTO_AUTH_DENIED`. Shared BDD uses mark/execution vocabulary, not checkout.
- **Internetmarke `marks.feature`:** Then steps match public `PortoMark` vocabulary (`created successfully` / `have an id`); Examples use catalog-valid weights and `none` for empty `service_ids`.
- **Docs:** package docs cover contracts only — dropped consumer-integration / Lab matrix pointer material from README and `docs/`.
- **BREAKING — Gherkin tags:** `@operator:{id}` → `@provider:{id}` (same id as `providers/` / `adapters/` directory names).
- **BREAKING — Internetmarke:** missing credentials on mark → `PORTO_AUTH_FAILED` (not `PORTO_CAPABILITY_UNSUPPORTED`).
- **BREAKING — Gherkin:** letter input is weight (+ optional envelope/product id), not letter `porto_id`; services/features use `kind` (not `porto_id` / native id); CLI price is country + weight.
- **Vocabulary:** Then asserts catalog `id` (not “native id”); phrase templates use `"<id>"`.
- **BREAKING — errors.json:** product details drop `porto_id`; remove `PORTO_LETTER_INVALID_TYPE` and `PORTO_ADDRESS_INVALID`.
- **BREAKING — errors.json renames:** `PORTO_MARK_GENERATION_FAILED` → `PORTO_MARK_FAILED`; `PORTO_MARK_VALIDATION_FAILED` → `PORTO_MARK_INVALID`.
- **BREAKING — errors.json:** `PORTO_LETTER_TOO_HEAVY` → `PORTO_TOO_HEAVY`; `PORTO_LETTER_TOO_LARGE` → `PORTO_TOO_LARGE`; `PORTO_LETTER_INVALID_DIMENSIONS` → `PORTO_INVALID_DIMENSIONS`; drop `PORTO_LETTER_INVALID_WEIGHT_TIER` (catalog miss → `PORTO_DATA_NOT_FOUND`; overweight → `PORTO_TOO_HEAVY`). `PORTO_DATA_SCHEMA_TOO_OLD` → `PORTO_DATA_TOO_OLD`; `PORTO_DATA_SCHEMA_TOO_NEW` → `PORTO_DATA_TOO_NEW`. No aliases.
- **BREAKING — errors.json:** drop `PORTO_FEATURE_UNSUPPORTED` (zero emitters; `can(FeatureKind)` is boolean), `PORTO_MARK_EXPIRED` (catalog-only), `PORTO_TOO_LARGE` and `PORTO_INVALID_DIMENSIONS` (no independent dimension check before product matching). Add `PORTO_SERVICE_UNSUPPORTED` for an explicit `ServiceKind` satisfied by neither a catalog service nor a product-included capability. No aliases.

### Added

- **sdk coverage:** La Poste `cheapest` + Swiss Post `fastest`/`economy` delivery-preference disambiguation; jurisdictions alpha-3 outline for IE/BG/US in `core/data.feature`.
- **cli.feature:** data-price scenarios use public `price()` via zone→country map (no catalog `(product, zone, weight)` path).
- **mark together:** unpaid 3-mark success (`core.mark.many_success`) in `sdk/core/mark.feature`; three `@heavy` Internetmarke 3-mark purchases by coverage type (domestic base / other-zone + service / feature-bearing), not a frozen catalog tuple. Gherkin uses `together`, not `many call`.
- Role-explicit address codes from `Porto.requires`: `PORTO_ADDRESS_{SENDER,RECIPIENT}_{REQUIRED,INVALID}` (covered in `sdk/core/mark.feature`).
- `PORTO_SERVICE_AMBIGUOUS` — multiple services match the requested `kind` (details require `kind`).
- `PORTO_SERVICE_UNSUPPORTED` — explicit `ServiceKind` with zero catalog rows and no product-included capability match (details require `kind`).

### Removed

- **`sdk/core/mark_requires.feature`:** address-require coverage folded into `sdk/core/mark.feature`.

## [0.4.0] - 2026-08-24

### Added

- `PORTO_CAPABILITY_UNSUPPORTED` — execution/billing capability absent (`mark` / `wallet`). Details require `capability`.
- **Jurisdiction address forms:** fixtures `invalid_postal_{DE,CH,FR,UA}`, `valid_postbox_{DE,UA}`; `valid_CH` uses 4-digit NPA; `sdk/core/validation.feature` outlines for DE/CH/FR/UA street + post-box success and postal-pattern failure; `details_schemas.PORTO_ADDRESS_INVALID` optional `field` / `reason` / `jurisdiction` / `form_issues` / `kind`.

### Changed

- Auth `details_schemas` for `PORTO_AUTH_FAILED`, `PORTO_AUTH_DENIED`, and `PORTO_LINKAGE_PENDING` now expose only opaque `provider_error`.
- **BREAKING — Gherkin letter contract:** resolve / get the price / inspect catalog; no shipping or shipment; restrictions via resolve; `@full` → `@heavy`; pricing matrix renamed; overweight and invalid-address paths use resolve or attempt-to-mark only.
- **BREAKING — errors.json renames:** `PORTO_DESTINATION_UNSUPPORTED` → `PORTO_DESTINATION_RESTRICTED`; `PORTO_DATA_SCHEMA_UNSUPPORTED` → `PORTO_DATA_SCHEMA_TOO_OLD` (missing version → `PORTO_DATA_INVALID`); `PORTO_REGISTERED_MAIL_*` → `PORTO_REGISTERED_*`.
- **BREAKING — errors.json descriptions:** auth triad (FAILED / DENIED / LINKAGE); letter invalid type; price not found; network timeout / rate-limited / unavailable; feature vs capability copy; mark wording uses PortoMark; services incompatible without `combinable_with`.
- **BREAKING — service features:** Then tokens use feature `porto_id` (`tracking`, not `tracking_number`).
- Wallet insufficient details: `portokasse_id` → `wallet_account_id`; destination restricted optional resolve-path fields.
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

### Removed

- **BREAKING:** `mark_simulate.feature`, CLI stamp simulate, CLI restrictions command, and public check-restrictions / sanctions steps.

### Chore

- Cursor agent rules consolidated (`features.mdc`, `contribution.mdc`); slim BUGBOT checklist.

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
- Docs: `matrix.md`, `scenarios.md`, `vocabulary.md` (tag casing, deprecated tag renames, canonical steps).
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
