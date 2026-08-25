# Step vocabulary

Canonical phrasing for shared BDD language across `porto-features`, Python SDK tests, and TypeScript SDK tests.

Gherkin is a **behavior contract**, not a copy of SDK method names. Domain nouns: **letter**, **Porto**, **mark** — not shipment or package.

```text
SDK façade          Gherkin
─────────────       ─────────────────────────────
resolve()           When I resolve the letter
price()             When I get the price
mark()              When I create a mark
prepare()           no Gherkin (not a customer step)
options()           When I list product options
restrict            dropped (eligibility lives in resolve)
catalog load        When I inspect … data
```

## Rules

- Use canonical phrases in new feature files.
- SDK step definitions must support canonical phrases first.
- Do not duplicate semantics with slightly different wording.
- Do not add SDK-only aliases for dropped phrases (`STANDARD`, stamp generate, `When I check restrictions`).

## Identifier layers

| Layer | In Gherkin | Example |
|-------|------------|---------|
| Letter input | **Given** weight (+ optional envelope / product id) | `the letter weight is 20 grams` |
| Catalog fact | **Then** native `id` | `product with id "standardbrief"` |
| Service input | **Given** service `kind` | `service kind is "registered"` |
| Service fact | **Then** native `id` | `service with id "einschreiben"` |
| Feature fact | **Then** feature `kind` | `the features should include kind "tracking"` |

Letter resolution uses **weight** (and optional **envelope id** or **product id**) at the SDK edge; native catalog `id` is the operator SKU in **Then** assertions. Catalog mapping and disambiguation rules live in **porto-data** — not duplicated here.

Do **not** use legacy tokens (`letter_standard`, `STANDARD`, `registered_mail`, letter `porto_id` buckets) as SDK input in new scenarios.

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
- `Given product id is "<native_id>"` (optional disambiguation)
- `Given delivery preference is "<preference>"`
- `When I resolve the letter`

### Resolution assertions

- `Then I should get product with id "<native_id>"`
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
- `Given I have product "<native_id>"`
- `Given zone id is "<zone_id>"` (adapter wire / product-zone setups)
- `When I get the price` (façade `price()` — do not use `When I pre-calculate the price`)
- `Then I should get a price in cents`
- `Then the price should be greater than 0`

### Catalog inspection

- `When I inspect products data` (and zones, prices, services, restrictions, envelopes, weight tiers, features)
- `When I inspect the provider registry`
- `When I inspect the execution manifest`
- `When I inspect denied party screening`
- Products: assert `id`, `name`, `label` only
- Services and features: assert `kind` (not `porto_id`)

### Services

- `Given service kind is "<kind>"`
- `Then the services array should contain service with id "<native_id>"`
- `Then the features should include kind "<feature_kind>"` (e.g. `tracking` — not native `sendungsnummer`)
- Customer capability phrases may stay (`tracking number capability`, `proof of mailing capability`)

### Mark execution

Paid adapter purchase only (`marks.feature`). Offline resolve is `When I resolve the letter` in `resolution.feature` — do not add simulate/stamp-generation phrases.

- `When I create a mark`
- `When I attempt to create a mark`
- `Then the mark should be created successfully`
- `Then the mark should have an id`
- `Then mark creation should fail`
- `Then I should get Porto error code "<code>"`

## Review checklist

- Does the scenario use weight (not letter `porto_id`) for letter input?
- Are native `id` values only in Then assertions?
- Do service Given steps use `service kind is`?
- Do feature Then steps use `kind` tokens?
- Is the Feature tagged `@sdk` or `@adapters`?
- Paid adapters: `@canary` or `@heavy` (not `@full` / `@release`)?
- Does `@adapters` match generated wire rows in Lab `labs/matrix/orders.generated.yaml`?
- Error scenarios: unique `@scenario:` and `PORTO_*` in `errors.json`?
- No `shipping` / `shipment`, `When I check restrictions`, `When I access`, or `When I prepare a mark order`?
