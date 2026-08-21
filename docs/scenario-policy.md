# Scenario policy

How we design `.feature` scenarios and tag paid adapter coverage. This package defines **contracts only** — step definitions and expensive execution live in implementor test suites.

See also: [matrix.md](matrix.md) — `cell_id` / `case_id` formats and Lab sync commands · [vocabulary.md](vocabulary.md) — canonical Gherkin steps.

## Confidence ratio

- **SDK:** 90–95% of scenarios (`@sdk`)
- **Adapters:** 5–10% (`@adapters` + `@canary` / `@heavy`)

`@sdk` scenarios cover resolution, pricing, services, restrictions, validation, metadata, delivery hints — anything verifiable from porto-data fixtures without carrier purchase.

`@adapters` scenarios describe integration health: auth, payload acceptance, mark purchase, wire codes. Running them may purchase marks when credentials are configured.

## Required tags

Every **Feature** must declare **`@sdk` or `@adapters`** at Feature level (exactly one).

### Scope tags (0.3+)

| Tag | Meaning | Package path |
|-----|---------|--------------|
| `@core` | Cross-operator contract (policy, metadata, address validation) | `features/sdk/core/` |
| `@operator:{id}` | Operator catalog or adapter scenarios | `features/sdk/providers/{id}/` or `features/adapters/{id}/` |
| `@wire:{integration}` | Execution integration id (`@adapters` only) | `features/adapters/{operator}/{integration}/` |

Adapter integration layout: **`adapters/{operator}/{integration}/marks.feature`** (successful mark purchase) and **`errors.feature`** (failure contracts). Directory names are provider + wire; file names are behavior (`marks`, `errors`). Failure expectations live in Gherkin (`@error` + `PORTO_*`); the declared catalog is `porto_features/errors.json`.

`@core` and `@operator:*` are mutually exclusive on `@sdk` features. Use **Gherkin Rules** when a feature mixes groups that need different Backgrounds (see `features/sdk/core/restrictions.feature`).

| Tag | Meaning |
|-----|---------|
| `@sdk` | No paid purchase when executed with catalog fixtures |
| `@adapters` | May purchase on a provider test account |
| `@canary` | Small paid smoke subset (`marks.feature` scenarios) |
| `@heavy` | Expensive wire matrix (`marks.feature` scenarios) |
| `@error` | Adapter failure contract (`errors.feature` scenarios); default — no purchase |
| `@auth` | Auth/token/linkage failure (`errors.feature`); may call auth APIs, no purchase |
| `@mark` | Error proven at purchase/checkout boundary (optional on `@error`; may spend) |

Do **not** use `@offline`, `@online`, or `@api` — deprecated.

### Tag casing

All Gherkin tags must be **lowercase** (including scenario tags):

- `@sdk`, `@adapters`, `@core`, `@canary`, `@heavy`, `@error`, `@auth`, `@mark`
- `@operator:deutschepost`, `@wire:internetmarke`

Do **not** use mixed-case legacy tags such as `@SDK`, `@Release`, or `@Heavy`. Renames from older conventions:

- `@offline` → `@sdk`
- `@online` / `@api` → `@adapters`
- `@release` → `@full` → `@heavy`

## Generated adapter matrix

Adapter `mark_order` Example rows and Lab `labs/matrix/orders.generated.yaml` are **generated** from porto-data wire cells. Regeneration: Lab [docs/labs/matrix.md](../../../docs/labs/matrix.md) — do not hand-edit generated matrix files.

Lab `orders.generated.yaml` may list all wire cells with `evidence: null` until a paid run attaches verification metadata. That is a coverage index scaffold, not proof that every cell has been exercised.

Hand-authored adapter scenarios should match generated wire rows; add or refine Gherkin only when catalog or wire behavior changes, using generated output as the structural source of truth.

## Do not fake mark simulation

Offline resolve is **`resolution.feature`**. Do not add `mark_simulate`, `stamp_generation`, or CLI `stamp simulate` scenarios (those hardcoded `simulation: true` and never created a PortoMark). Real purchase is `When I create a mark` on `@adapters` `marks.feature`.

## Paid adapter rules

- No unbounded loops in paid scenarios.
- Explicit maximum paid examples per pipeline.
- Balance threshold check before any paid action in implementor runners.
- **`@auth` simulated** scenarios (offline HTTP body mapping) are CI-safe; **`@auth` live probes** require Internetmarke env credentials and network (lab-only).
- **`@mark`** scenarios require credentials and may spend Portokasse balance (lab-only).

## Fixture strategy

Reuse canonical address fixtures under `porto_features/fixtures/addresses/`:

| File | Role | City (fixture pun) |
|------|------|-------------------|
| `origin_DE.json` | Sender | Lickofurt am Internet |
| `valid_DE.json` | Domestic recipient (jurisdiction form DE / DIN678) | Lickofurt am Internet |
| `valid_FR.json` | EU / La Poste (jurisdiction form FR / NFZ10011) | Licko-sur-Seine |
| `valid_CH.json` | Swiss Post domestic (jurisdiction form CH / SN010130; 4-digit NPA) | Licko am Sur-Lago |
| `invalid_postal_DE.json` | DE form: wrong postal length | Lickofurt am Internet |
| `invalid_postal_CH.json` | CH form: wrong postal length | Licko am Sur-Lago |
| `invalid_postal_FR.json` | FR form: wrong postal length | Licko-sur-Seine |
| `invalid_postal_UA.json` | UA form: wrong postal length | Velykyi Lickon |
| `valid_UA.json` | Ukrposhta street form (`UKRPOSHTA`); Deutsche Post `zone_2_europe`; UA restriction scenarios | Velykyi Lickon |
| `valid_postbox_DE.json` | DE `post_box` form (Postfach id) | Lickofurt am Internet |
| `valid_postbox_UA.json` | UA `post_box` form (п/с id) | Velykyi Lickon |
| `valid_US.json` | World / Deutsche Post | New Licko |
| `restricted_UA.json` | Prohibited region (`UA-14` / Donetsk oblast) | Velikyy Lickon |

Shared street rows use `street: Python-TypeScript`, `house_number: 1`. Post-box rows use `post_box` (no street/house_number). Postal codes follow jurisdiction forms (`DE`/`FR`/`UA` 5-digit e.g. `01001`; `CH` 4-digit e.g. `6900`). Fixture ids map to **jurisdiction** address forms in `formats/addresses.json`, not provider wire encoding. `restricted_UA` restriction is keyed by `country_code` + `region_code` (`UA-14`), not city name.

**Planned (not shipped in 0.3):** `valid_NO.json` (Norway / Deutsche Post non-EU Europe zone) — do not reference in scenarios until the fixture lands.

## When porto-data changes

1. Check diffs in affected provider catalogs and `policy/`.
2. Update only affected scenarios/fixtures.
3. Regenerate matrix artifacts when wire or `@sdk` coverage changes — see [matrix.md](matrix.md).
4. Re-evaluate Lab `labs/matrix/canary.yaml` if wire or pricing behavior changed.
