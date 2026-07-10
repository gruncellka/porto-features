# Porto Features

[![validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml/badge.svg)](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
[![codecov](https://codecov.io/gh/gruncellka/porto-features/branch/main/graph/badge.svg)](https://codecov.io/gh/gruncellka/porto-features)

**Structured BDD contracts for Porto SDKs** — Gherkin scenarios and JSON fixtures aligned with [porto-data](https://github.com/gruncellka/porto-data).

---

## Install

```bash
npm install -D @gruncellka/porto-features
pip install "gruncellka-porto-features[dev]"
```

Shipped paths: `porto_features/features/**/*.feature` · `porto_features/matrix/*.yaml` · `porto_features/fixtures/**/*.json`

---

## Validate locally

```bash
make
make quality
make test-cov
```

---

## Documentation

- **[docs/README.md](docs/README.md)** — doc hub
- **[docs/vocabulary.md](docs/vocabulary.md)** — canonical Gherkin steps (`porto_id` input)
- **[docs/matrix.md](docs/matrix.md)** — SDK + adapter coverage index, `@sdk` / `@adapters` tags
- **[docs/scenario-policy.md](docs/scenario-policy.md)** — tag policy, lab promotion
- **[docs/catalog-alignment.md](docs/catalog-alignment.md)** — porto-data mapping for scenario authors

---

## Feature layout

| Path | Tag | Focus |
|------|-----|-------|
| `features/sdk/resolution.feature` | `@sdk` | Product, zone, weight tier resolution |
| `features/sdk/pricing.feature` | `@sdk` | Price lookup by native id × zone × weight |
| `features/sdk/services.feature` | `@sdk` | Service catalog and add-ons |
| `features/sdk/delivery_resolution.feature` | `@sdk` | Delivery hints and disambiguation |
| `features/sdk/metadata.feature` | `@sdk` | Bundle metadata and provider registry |
| `features/sdk/product_options.feature` | `@sdk` | Ambiguous porto_id product picks |
| `features/sdk/data_access.feature` | `@sdk` | Catalog entity access |
| `features/sdk/restrictions.feature` | `@sdk` | Sanctions and compliance |
| `features/sdk/validation.feature` | `@sdk` | Letter and address validation |
| `features/cli.feature` | `@sdk` | CLI contract |
| `features/sdk/stamp_generation.feature` | `@sdk` | Mark generation (SDK-only paths) |
| `features/sdk/api_comprehensive_testing.feature` | `@sdk` | Pairwise pre-calculate matrix |
| `features/adapters/internetmarke.feature` | `@adapters` | Paid Internetmarke stamp orders |

🔳 gruncellka
