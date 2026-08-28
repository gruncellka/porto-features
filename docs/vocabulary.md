# Step vocabulary

Canonical phrasing for shared BDD language in this package.

Gherkin is a **behavior contract**, not a copy of implementor method names. Domain nouns: **letter**, **Porto**, **mark** — not shipment or package.

```text
Intent              Gherkin
─────────────       ─────────────────────────────
resolve             When I resolve the letter
price               When I get the price
mark                When I create a mark
prepare             no Gherkin (not a customer step)
options             When I list product options
restrict            dropped (eligibility lives in resolve)
catalog load        When I inspect … data
```

## Rules

- Use canonical phrases in new feature files.
- Do not duplicate semantics with slightly different wording.
- Do not add aliases for dropped phrases (`STANDARD`, stamp generate, `When I check restrictions`).

## Identifier layers

| Layer | In Gherkin | Example |
|-------|------------|---------|
| Letter input | **Given** weight (+ optional envelope / product id) | `the letter weight is 20 grams` |
| Catalog fact | **Then** catalog `id` | `product with id "standardbrief"` |
| Service input | **Given** service `kind` | `service kind is "registered"` |
| Service fact | **Then** catalog `id` | `service with id "einschreiben"` |
| Feature fact | **Then** feature `kind` | `the features should include kind "tracking"` |

Letter resolution uses **weight** (and optional **envelope id** or **product id**); catalog `id` is the provider SKU in **Then** assertions. Catalog mapping and disambiguation rules live in **porto-data** — not duplicated here.

Do **not** use legacy tokens (`letter_standard`, `STANDARD`, `registered_mail`, letter `porto_id` buckets) as letter input in new scenarios.

Do **not** use `small letter` / `medium letter` / `large letter` as tariff classes. `letter` is narrative; catalog `id` is the assertion.

## Shipping / shipment (forbidden in features)

| Do not write | Write |
|--------------|-------|
| shipping costs | price |
| shipping services | products (catalog) or additional services (Einschreiben) |
| shipping requirements | mailing requirements |
| shipment | letter |
| `Reject shipment…` | `Cannot resolve letter…` |

## Canonical phrases

### Resolution setup

- `Given provider is "<provider>"`
- `Given I want to send a letter to country "<country_code>"`
- `Given the letter weight is <weight> grams`
- `Given envelope id is "<envelope_id>"` (optional)
- `Given product id is "<id>"` (optional disambiguation)
- `Given delivery preference is "<preference>"`
- `When I resolve the letter`

### Resolution assertions

- `Then I should get product with id "<id>"`
- `Then I should get zone with id "<zone_id>"`
- `Then I should get weight tier "<tier_id>"`
- `Then delivery hint span should be "<span>"`
- `Then delivery hint days max should be <days>`
- `Then delivery hint weekdays should be "<weekdays>"`
- `Then the resolution should be invalid`
- `Then I should get Porto error code "<code>"`

### Pricing

- `Given I want to send a letter to country "<country_code>"`
- `Given the letter weight is <weight> grams`
- `Given I have product "<id>"`
- `Given zone id is "<zone_id>"` (adapter wire / product-zone setups)
- `When I get the price` (do not use `When I pre-calculate the price`)
- `Then I should get a price in cents`
- `Then the price should be greater than 0`

### Catalog inspection

Shared/core BDD lists public surfaces only:

- `When I inspect envelopes data`
- `When I inspect the provider registry`
- `When I list product options`

Provider-native product ids belong in `providers/<id>/` features, not in shared catalog dumps.

### Services

- `Given service kind is "<kind>"`
- `Then the services array should contain service with id "<id>"`
- `Then the features should include kind "<feature_kind>"` (e.g. `tracking` — not catalog id `sendungsnummer`)
- Customer capability phrases may stay (`tracking number capability`, `proof of mailing capability`)

### Mark execution

Paid adapter purchase only (`marks.feature`). Offline resolve is `When I resolve the letter` in `resolution.feature` — do not add simulate/stamp-generation phrases.

- `When I create a mark`
- `When I attempt to create a mark`
- `When I create three equivalent marks together`
- `When I attempt to create the marks together`
- `Then the mark should be created successfully`
- `Then the mark should have an id`
- `Then three marks should be returned`
- `Then every returned mark should have an id`
- `Then the returned mark ids should be distinct`
- `Then the returned marks should share one external id`
- `Then mark creation should fail`
- `Then I should get Porto error code "<code>"`
- `Given a resolved stamp Porto covering "<coverage>"` (coverage types: domestic base / other-zone + service / feature-bearing; catalog combo is not frozen)

## Review checklist

- Does the scenario use weight (not letter `porto_id`) for letter input?
- Are catalog `id` values only in Then assertions (or an optional product-id pin in Given)?
- Do service Given steps use `service kind is`?
- Do feature Then steps use `kind` tokens?
- Is the Feature tagged `@sdk` or `@adapters`?
- Paid adapters: `@canary` or `@heavy` (not `@full` / `@release`)?
- Error scenarios: unique `@scenario:` and `PORTO_*` in `errors.json`?
- No `shipping` / `shipment`, `When I check restrictions`, `When I access`, or `When I prepare a mark order`?
