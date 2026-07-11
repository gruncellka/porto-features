# Scenario policy

How we design `.feature` scenarios and tag paid adapter coverage. This package defines **contracts only** — step definitions and expensive execution live in implementor test suites.

See also: [matrix.md](matrix.md) — `cell_id` / `case_id` formats and Lab sync commands · [vocabulary.md](vocabulary.md) — canonical Gherkin steps.

## Confidence ratio

- **SDK:** 90–95% of scenarios (`@sdk`)
- **Adapters:** 5–10% (`@adapters` + `@canary` / `@full`)

`@sdk` scenarios cover resolution, pricing, services, restrictions, validation, metadata, delivery hints — anything verifiable from porto-data fixtures without carrier purchase.

`@adapters` scenarios describe integration health: auth, payload acceptance, stamp generation, wire codes. Running them may purchase postage when credentials are configured.

## Required tags

Every **Feature** must declare **`@sdk` or `@adapters`** at Feature level (exactly one).

### Scope tags (0.4+)

| Tag | Meaning | Package path |
|-----|---------|--------------|
| `@core` | Cross-operator contract (policy, metadata, address validation) | `features/sdk/core/` |
| `@operator:{id}` | Operator catalog or adapter scenarios | `features/sdk/providers/{id}/` or `features/adapters/{id}/` |
| `@wire:{adapter}` | Paid integration wire id (`@adapters` only) | with matching `@operator:*` |

`@core` and `@operator:*` are mutually exclusive on `@sdk` features. Use **Gherkin Rules** when a feature mixes groups that need different Backgrounds (see `features/sdk/core/restrictions.feature`).

| Tag | Meaning |
|-----|---------|
| `@sdk` | No paid purchase when executed with catalog fixtures |
| `@adapters` | May purchase on a provider test account |
| `@canary` | Small paid smoke subset (on adapter scenarios) |
| `@full` | Full wire matrix (on adapter scenarios) |

Do **not** use `@offline`, `@online`, or `@api` — deprecated.

## Generated adapter matrix

Adapter `stamp_order` Example rows and `matrix/orders.generated.yaml` are **generated** from porto-data wire cells. Regeneration: [matrix.md](matrix.md) — do not hand-edit generated files in this repo.

`orders.generated.yaml` may list all wire cells with `evidence: null` until a paid run attaches verification metadata. That is a coverage index scaffold, not proof that every cell has been exercised.

Hand-authored adapter scenarios should match generated wire rows; add or refine Gherkin only when catalog or wire behavior changes, using generated output as the structural source of truth.

## Paid adapter rules

- No unbounded loops in paid scenarios.
- Explicit maximum paid examples per pipeline.
- Balance threshold check before any paid action in implementor runners.

## Fixture strategy

Reuse canonical address fixtures under `porto_features/fixtures/addresses/`:

| File | Role | City (fixture pun) |
|------|------|-------------------|
| `origin_DE.json` | Sender | Lickofurt am Internet |
| `valid_DE.json` | Domestic recipient | Lickofurt am Internet |
| `valid_FR.json` | EU / La Poste | Licko-sur-Seine |
| `valid_CH.json` | Swiss Post domestic | Licko am Sur-Lago |
| `valid_UA.json` | Ukrposhta; Deutsche Post `zone_2_europe`; UA restriction scenarios | Velykyi Lickon |
| `valid_US.json` | World / Deutsche Post | New Licko |
| `restricted_UA.json` | Prohibited region (`UA-14` / Donetsk oblast) | Velikyy Lickon |

Shared rows use `street: Python-TypeScript`, `house_number: 1`, `postal_code: 01001`. `restricted_UA` restriction is keyed by `country_code` + `region_code` (`UA-14`), not city name.

**Planned (not shipped in 0.4):** `valid_NO.json` (Norway / Deutsche Post non-EU Europe zone) — do not reference in scenarios until the fixture lands.

## When porto-data changes

1. Check diffs in affected provider catalogs and `policy/`.
2. Update only affected scenarios/fixtures.
3. Regenerate matrix artifacts when wire or `@sdk` coverage changes — see [matrix.md](matrix.md).
4. Re-evaluate `canary.yaml` if wire or pricing behavior changed.
