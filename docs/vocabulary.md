# Step vocabulary

Canonical phrasing for shared BDD language across `porto-features`, Python SDK tests, and TypeScript SDK tests.

## Rules

- Use canonical phrases in new feature files.
- SDK step definitions must support canonical phrases first.
- Legacy phrase variants are supported via aliases in SDK test suites only.
- Do not duplicate semantics with slightly different wording.

## Identifier layers

| Layer | In Gherkin | Example |
|-------|------------|---------|
| SDK input | **Given** `porto_id` | `the letter porto_id is "small"` |
| Catalog fact | **Then** native `id` | `product with id "standardbrief"` |
| Service input | **Given** service `porto_id` | `service porto_id is "registered"` |
| Service fact | **Then** native `id` | `service with id "einschreiben"` |

`porto_id` is a size or service **bucket** at the SDK edge; native `id` is the operator catalog SKU in **Then** assertions. Catalog mapping and disambiguation rules live in **porto-data** — not duplicated here.

Do **not** use legacy tokens (`letter_standard`, `STANDARD`, `registered_mail`) as SDK input in new scenarios.

## Canonical phrases

### Resolution setup

- `Given provider is "<provider>"`
- `Given I want to send a letter to country "<country_code>"`
- `Given the letter weight is <weight> grams`
- `Given the letter porto_id is "<porto_id>"`
- `Given delivery preference is "<preference>"`
- `When I resolve the shipping configuration`

### Resolution assertions

- `Then I should get product with id "<native_id>"`
- `Then I should get zone with id "<zone_id>"`
- `Then I should get weight tier "<tier_id>"`
- `Then delivery hint span should be "<span>"`
- `Then delivery hint days max should be <days>`
- `Then delivery hint weekdays should be "<weekdays>"`

### Pricing

- `Given I have a letter with porto_id "<porto_id>"`
- `Given I have product "<native_id>"`
- `When I calculate the price`
- `Then I should get a price in cents`

### Services

- `Given service porto_id is "<porto_id>"`
- `Then the services array should contain service with id "<native_id>"`

## Allowed aliases (SDK only — avoid in new features)

| Canonical | Legacy alias |
|-----------|--------------|
| `the letter porto_id is "small"` | `the letter type is "STANDARD"` |
| `I have a letter with porto_id "medium"` | `I have a letter with type "COMPACT"` |
| `service porto_id is "registered"` | `I want to add service "registered_mail"` |

## Review checklist

- Does the scenario use `porto_id` for SDK input?
- Are native `id` values only in Then assertions?
- Is the Feature tagged `@sdk` or `@adapters`?
- Does `@adapters` match generated wire rows in `orders.generated.yaml`?
