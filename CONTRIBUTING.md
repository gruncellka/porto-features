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
| `porto_features/errors.json` | Authored `PORTO_*` taxonomy |
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
2. `make check`.
3. `make quality` and `make test-cov`.
4. Note behavior changes under `CHANGELOG.md` → `[Unreleased]`.
5. Commit (pre-commit runs automatically).

CI runs `make quality` and `make test-cov` only.

## Commands

| Command | Description |
| ------- | ----------- |
| `make` | venv + hooks |
| `make help` | Show all commands |
| `make check` | Features + fixtures + `@error` vs `errors.json` (`make validate` is the same target) |
| `make check-error-contracts` | `@error` contracts only |
| `make quality` | validate + lint + format + type-check |
| `make test-cov` | Script tests with coverage gate (≥90%) |
| `make test-publish` | npm + PyPI smoke test |

`make check` runs `scripts/validate_features.py` (tags, vocabulary guards, gherlint) and `scripts/validate_error_contracts.py` (unique `@scenario:` ids; declared `PORTO_*` codes).

## Releases

`main` is the integration branch. Packages: npm `@gruncellka/porto-features` · PyPI `gruncellka-porto-features`.

1. Integrate on `main`; accumulate `[Unreleased]` in `CHANGELOG.md`.
2. Cut `release/X.Y.Z` from stable `main`.
3. On the release branch: dated changelog section; `bump2version` (`tag = False`); `make quality` and `make test-cov`.
4. Tag `vX.Y.Z` manually; push branch and tag. Tag push triggers `.github/workflows/publish.yml`.
5. Merge the release branch back to `main`.
