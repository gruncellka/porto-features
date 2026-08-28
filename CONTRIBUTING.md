# Contributing to Porto Features

Shared BDD contract (`.feature` + fixtures + `errors.json`). This package does not ship step definitions or test runners.

## Setup

```bash
make
```

First run creates `venv`, installs dev dependencies, and installs pre-commit hooks. Targets use the venv automatically.

## Layout

| Path | Role |
|------|------|
| `porto_features/features/sdk/core/` | Cross-provider `@sdk` `@core` |
| `porto_features/features/sdk/providers/{id}/` | Provider catalog `@sdk` `@provider:{id}` |
| `porto_features/features/adapters/{id}/{wire}/` | `marks.feature` + `errors.feature` |
| `porto_features/errors.json` | Authored `PORTO_*` taxonomy (SoT for public code strings; SDK enums are generated from `codes[]`) |
| `porto_features/fixtures/addresses/` | Shared address JSON |

## Writing scenarios

1. Behavior contract only — no implementor class or module names in steps.
2. Letter input = weight (+ optional envelope or product id); service input = `kind`; Then may assert catalog `id` or feature `kind`.
3. Domain nouns: **letter**, **Porto**, **mark** — not shipment/package.
4. Prefer Rules + Background when a Feature mixes setup groups.
5. Offline resolve belongs in `resolution.feature` — never fake mark simulation.
6. Do not reintroduce legacy tokens (`letter_standard`, `STANDARD`, `registered_mail`, letter `porto_id` buckets).

Canonical phrases: **[docs/vocabulary.md](docs/vocabulary.md)**.

## Tags

| Tag | Meaning |
|-----|---------|
| `@sdk` / `@adapters` | Exactly one at Feature level |
| `@core` | Cross-provider (`features/sdk/core/`) |
| `@provider:{id}` | Path under `sdk/providers/` or `adapters/` |
| `@wire:{id}` | Required on `@adapters` Features |
| `@canary` / `@heavy` | Paid smoke vs expensive wire matrix (`marks.feature`) |
| `@error` / `@auth` / `@mark` | Failure contracts on `errors.feature` |

All tags lowercase. Do not use `@operator:`, `@offline`, `@online`, `@api`, `@full`, `@release`.

Full table and fixtures: **[docs/scenarios.md](docs/scenarios.md)**.

## Adapter and live tests

Paid coverage is `@canary` (smoke) or `@heavy` (wire matrix) on `marks.feature`. Failures go in `errors.feature` with `@error` + `@scenario:…` and a `PORTO_*` code in `errors.json`. Simulated `@auth` is CI-safe; live `@auth` / `@mark` need credentials. No unbounded purchase loops.

Do not hand-edit generated Example tables on adapter Features.

## Adding scenarios

**Provider (`@sdk`):** `features/sdk/providers/{id}/*.feature` with `@sdk` + `@provider:{id}`. Assert catalog facts; mapping rules stay in porto-data.

**Adapter (`@adapters`):** `features/adapters/{id}/{wire}/marks.feature` and/or `errors.feature` with `@adapters` + `@provider:{id}` + `@wire:{wire}`. Success → `marks.feature` (`@canary` / `@heavy`). Failures → `errors.feature` with `@error` + `@scenario:…` and a code in `errors.json`.

## Workflow

1. Edit features / fixtures / `errors.json`.
2. Run validation leaves locally (`make features`, `make fixtures`, `make errors`, `make format`, `make lint`, `make types`, `make test`) or rely on pre-commit + CI.
3. Note behavior changes under `CHANGELOG.md` → `[Unreleased]`.
4. Commit (pre-commit runs automatically).

CI runs parallel leaf jobs (`features`, `fixtures`, `errors`, `format`, `lint`, `types`, `test`) and aggregates in `validate` — require **`validate`** for branch protection.

## Commands

| Command | Description |
| ------- | ----------- |
| `make` | venv + hooks |
| `make help` | Show all commands |
| `make validate` | features + fixtures + errors (contract umbrella) |
| `make features` | Gherkin tags, vocabulary, layout (`scripts/validate_features.py`) |
| `make fixtures` | Address JSON fixtures |
| `make errors` | `@error` scenarios vs `errors.json` |
| `make format` | Check Python + JSON formatting (rewrite via pre-commit) |
| `make lint` | Gherkin + Python |
| `make types` | Static types |
| `make test` | Script tests with coverage gate (100%) |
| `make artifact` | build npm+PyPI once, verify, smoke (keeps tarball + `dist/`) |

## Releases

`main` is the integration branch. Packages: npm `@gruncellka/porto-features` · PyPI `gruncellka-porto-features`.

1. Integrate on `main`; accumulate `[Unreleased]` in `CHANGELOG.md`.
2. Cut `release/X.Y.Z` from stable `main`.
3. On the release branch: dated changelog section; `bump2version` (`tag = False`); run validation leaves through `make test`.
4. Tag `vX.Y.Z` manually; push branch and tag. Tag push triggers `.github/workflows/publish.yml`.
5. Merge the release branch back to `main`.
