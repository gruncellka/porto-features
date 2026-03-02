# Porto Features

[![validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml/badge.svg)](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
[![codecov](https://codecov.io/gh/gruncellka/porto-features/branch/main/graph/badge.svg)](https://codecov.io/gh/gruncellka/porto-features)

**Structured feature specifications for Porto SDKs**

A validated collection of Gherkin feature files and JSON fixtures that define behavioral contracts for Python and TypeScript SDKs. Files are checked in CI and packaged for distribution on **npm** and **PyPI**.

---

## Install

**npm** (scope: `@gruncellka`)

```bash
npm install @gruncellka/porto-features
```

**PyPI (Python)**

```bash
pip install gruncellka-porto-features
```

The package includes `porto_features/features/*.feature` and `porto_features/fixtures/**/*.json`, so SDK tests can run offline with the same source of truth in both ecosystems.

- **PyPI**: import `porto_features`; use files under `porto_features/features` and `porto_features/fixtures`.
- **npm**: files live under `porto_features/` in `node_modules/@gruncellka/porto-features/`.

---

## Use cases

SDK contract tests (Python/TypeScript parity), BDD documentation, regression safety during SDK releases.

---

## Validate locally

```bash
make setup
make quality
make test-coverage
```

This runs feature/fixture validation, Gherkin linting, Python lint/format checks, type checks, and test coverage gates used by CI.

---

## Feature statistics

9 feature files; 80+ scenarios across API, CLI, pricing, restrictions, validation, services, and stamp generation. Address fixtures include DE, FR, CH, GB, NO, UA, US, and DE sender origin.

---

## Feature and fixture overview

| File                                 | Description                                |
| ------------------------------------ | ------------------------------------------ |
| `api_comprehensive_testing.feature`  | End-to-end API behavior scenarios          |
| `cli.feature`                        | CLI usage and output behavior              |
| `data_access.feature`                | Data loading and access behavior           |
| `pricing.feature`                    | Pricing logic by type/zone/weight          |
| `resolution.feature`                 | Resolution workflow behavior               |
| `restrictions.feature`               | Restrictions and sanctions behavior         |
| `services.feature`                   | Service catalog behavior                   |
| `stamp_generation.feature`           | Stamp generation behavior                  |
| `validation.feature`                 | Validation and error behavior              |
| `porto_features/fixtures/addresses/*.json` | Test addresses by country/zone       |

Feature files are validated via `scripts/validate_features.py`, and fixture JSON files are validated via `scripts/validate_fixtures.py`. Fixtures are shipped for deterministic tests.

---

## Standards

- **Feature format**: Gherkin (`.feature`), Cucumber-compatible
- **Fixture format**: JSON (`.json`)
- **Country codes**: ISO 3166-1 alpha-2 (`DE`, `US`, `FR`, `UA`)

---

## Disclaimer

This is **reference feature specification data** for Porto SDKs. Always verify that SDK implementations and runtime behavior match these specifications before shipping to production.

---

## Related resources

- [Gherkin syntax](https://cucumber.io/docs/gherkin/)
- [Cucumber docs](https://cucumber.io/docs/)
- [BDD](https://cucumber.io/docs/bdd/)

---

🔳 gruncellka
