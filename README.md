# Porto Features

[![validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml/badge.svg)](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
[![codecov](https://codecov.io/gh/gruncellka/porto-features/branch/main/graph/badge.svg)](https://codecov.io/gh/gruncellka/porto-features)

**Structured BDD contracts for Porto SDK** — shared Gherkin scenarios, address fixtures, and `errors.json` catalog.

---

## Install

**TypeScript / JavaScript (npm)**

```bash
npm install -D @gruncellka/porto-features
```

**Python (PyPI)**

```bash
pip install "gruncellka-porto-features[dev]"
```

Shipped paths: `porto_features/errors.json` · `porto_features/features/**/*.feature` · `porto_features/fixtures/**/*.json`


---

## Validate locally

```bash
make
make check
make quality
make test-cov
```

---

## Documentation

- **[docs/vocabulary.md](docs/vocabulary.md)** — canonical Gherkin steps (`porto_id` input)
- **[docs/scenario-policy.md](docs/scenario-policy.md)** — tag policy, paid adapter rules, fixtures
- **[docs/matrix.md](docs/matrix.md)** — pointer to Lab coverage index (`labs/matrix/`)

Catalog facts and mapping tables live in **porto-data** — not duplicated here.

---

## Feature layout

```text
porto_features/
├── errors.json                  # PORTO_* catalog (SDKs build language bindings)
├── features/
│   ├── sdk/
│   │   ├── core/                # @sdk @core — cross-operator policy, CLI, metadata
│   │   └── providers/{operator}/
│   └── adapters/{operator}/
│       └── {integration}/
│           ├── marks.feature
│           └── errors.feature
└── fixtures/addresses/
```

See [docs/scenario-policy.md](docs/scenario-policy.md) for tag and path rules.

🔳 gruncellka
