# Porto Features

[![validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml/badge.svg)](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
[![codecov](https://codecov.io/gh/gruncellka/porto-features/branch/main/graph/badge.svg)](https://codecov.io/gh/gruncellka/porto-features)

**Structured BDD contracts for postal SDKs** — Gherkin scenarios and JSON fixtures aligned with [porto-data](https://github.com/gruncellka/porto-data).

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
- **[docs/scenario-policy.md](docs/scenario-policy.md)** — tag policy, paid adapter rules
- **[docs/alignment.md](docs/alignment.md)** — porto-data mapping for scenario authors

---

## Feature layout

```text
porto_features/features/
├── sdk/
│   ├── core/                    # @sdk @core — cross-operator policy, CLI, metadata
│   └── providers/{operator}/    # @sdk @operator:{id} — operator catalog scenarios
└── adapters/{operator}/         # @adapters @operator:{id} @wire:{adapter}
```

| Path | Tags | Focus |
|------|------|-------|
| `features/sdk/core/restrictions.feature` | `@sdk` `@core` | Sanctions and compliance (Rules) |
| `features/sdk/core/validation.feature` | `@sdk` `@core` | Address validation |
| `features/sdk/core/metadata.feature` | `@sdk` `@core` | Bundle metadata and provider registry |
| `features/sdk/core/data_access.feature` | `@sdk` `@core` | Catalog entity access |
| `features/sdk/core/cli.feature` | `@sdk` `@core` | CLI contract |
| `features/sdk/providers/deutschepost/*.feature` | `@sdk` `@operator:deutschepost` | DP resolution, pricing, services, … |
| `features/sdk/providers/laposte/*.feature` | `@sdk` `@operator:laposte` | La Poste disambiguation and options |
| `features/sdk/providers/ukrposhta/*.feature` | `@sdk` `@operator:ukrposhta` | Ukrposhta product options |
| `features/adapters/deutschepost/internetmarke.feature` | `@adapters` `@operator:deutschepost` `@wire:internetmarke` | Paid Internetmarke stamp orders |

🔳 gruncellka
