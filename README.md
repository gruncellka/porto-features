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

- **[docs/vocabulary.md](docs/vocabulary.md)** — canonical Gherkin steps (`porto_id` input)
- **[docs/scenario-policy.md](docs/scenario-policy.md)** — tag policy, paid adapter rules, fixtures
- **[docs/matrix.md](docs/matrix.md)** — coverage index, `cell_id` / `case_id`, Lab sync

Catalog facts and mapping tables live in **porto-data** — not duplicated here.

---

## Feature layout

```text
porto_features/features/
├── sdk/
│   ├── core/                    # @sdk @core — cross-operator policy, CLI, metadata
│   └── providers/{operator}/    # @sdk @operator:{id} — operator catalog scenarios
└── adapters/{operator}/         # @adapters @operator:{id} @wire:{adapter}
```

See [docs/scenario-policy.md](docs/scenario-policy.md) for tag and path rules.

🔳 gruncellka
