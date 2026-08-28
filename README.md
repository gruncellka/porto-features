# Porto Features

[![validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml/badge.svg)](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
[![codecov](https://codecov.io/gh/gruncellka/porto-features/branch/main/graph/badge.svg)](https://codecov.io/gh/gruncellka/porto-features)

**Shared behavioral contracts for Porto SDK implementations** — Gherkin scenarios, address fixtures, and `errors.json`. This package ships the contract only.

Catalog facts stay in **[porto-data](https://github.com/gruncellka/porto-data)**. This package says *what behavior must hold*, not *what the tariff tables contain*.

---

## Install

```bash
npm install -D @gruncellka/porto-features
# or
pip install "gruncellka-porto-features[dev]"
```

Shipped: `porto_features/errors.json` · `porto_features/features/**/*.feature` · `porto_features/fixtures/**/*.json`

---

## Example

**Core** — shared resolve contract (cross-provider invariants):

```gherkin
@sdk
@core
Feature: Public resolution contract

  Scenario: Destination and weight resolve a Porto without product pin
    Given provider is "deutschepost"
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then the resolution should be valid
    And the resolved amount should be a positive number
```

**Provider** — real provider catalog behavior:

```gherkin
@sdk
@provider:deutschepost
Feature: Deutsche Post resolution

  Scenario: Resolve 20 g domestic to standardbrief
    Given provider is "deutschepost"
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
```

```text
core       → cross-provider contract
providers  → provider catalog contract
adapters   → wire / execution contract
```

Canonical Gherkin phrases: [docs/vocabulary.md](docs/vocabulary.md).

---

## Layout

```text
porto_features/
├── errors.json                         # PORTO_* catalog
├── features/
│   ├── sdk/
│   │   ├── core/                       # @sdk @core
│   │   └── providers/{id}/             # @sdk @provider:{id}
│   └── adapters/{id}/{wire}/           # @adapters @provider:{id} @wire:{id}
│       ├── marks.feature
│       └── errors.feature
└── fixtures/addresses/
```

Tags: [docs/scenarios.md](docs/scenarios.md).

---

🔳 gruncellka
