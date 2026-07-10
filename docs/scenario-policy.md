# Scenario policy

How we design `.feature` scenarios and control paid adapter usage. Aligns with Porto SDK Lab [LAB_BOUNDARIES.md](https://github.com/gruncellka/porto-sdk-lab/blob/main/docs/labs/LAB_BOUNDARIES.md).

See also: [matrix.md](matrix.md) — coverage index and glossary.

## Confidence ratio

- **SDK:** 90–95% of scenarios (`@sdk`)
- **Adapters:** 5–10% (`@adapters` + `@canary` / `@full`)

SDK scenarios cover resolution, pricing, services, restrictions, validation, metadata, delivery hints — anything verifiable from porto-data fixtures without carrier purchase.

Adapter scenarios validate integration health only: auth, payload acceptance, stamp generation, wire codes.

## Required tags

Every **Feature** must declare **`@sdk` or `@adapters`** at Feature level (exactly one).

| Tag | Meaning | CI |
|-----|---------|-----|
| `@sdk` | No paid purchase | Runs in PR CI |
| `@adapters` | May purchase on test Portokasse | Lab / manual only |
| `@canary` | Daily paid smoke (on adapter scenarios) | Lab cron |
| `@full` | Weekly full paid matrix | Lab cron |

Do **not** use `@offline`, `@online`, or `@api` — deprecated.

## Lab → porto-features promotion

1. Run paid experiments in lab with full artifacts under `labs/experiments/runs/<id>/`.
2. Analyze failures, wire codes, auth errors.
3. Add or refine Gherkin **only** for scenarios with evidence.
4. SDK CI consumes published porto-features; lab does not duplicate scenario definitions.

**Promotion checklist:**

- Lab `case_id` green on both Py + TS → candidate for adapter scenario outline
- Capture expected wire code, price band, error codes in Examples
- Tag `@adapters @canary` or `@adapters @full` only after lab artifact linked in PR description

## Paid adapter rules

- No unbounded loops in paid tests.
- Explicit maximum paid scenarios per pipeline.
- Balance threshold check before any paid action.
- `make test-api-*` on SDK packages is **not** the supported paid path — use `make labs-internetmarke-*`.

## Fixture strategy

Reuse canonical address fixtures under `porto_features/fixtures/addresses/` (aligned with lab Internetmarke matrix — `labs/experiments/internetmarke/order_matrix.py`):

| File | Role | City (lab pun) |
|------|------|----------------|
| `origin_DE.json` | Sender (`Porto SDK`) | Lickofurt am Internet |
| `valid_DE.json` | Domestic recipient | Lickofurt am Internet |
| `valid_FR.json` | EU / La Poste | Licko-sur-Seine |
| `valid_CH.json` | Swiss Post; Deutsche Post `zone_2_europe` | Licko am Sur-Lago |
| `valid_UA.json` | Ukrposhta; UA restriction scenarios (not DP `zone_2_europe`) | Velykyi Lickon |
| `valid_US.json` | World / Deutsche Post | New Licko |
| `restricted_UA.json` | Prohibited region (`UA-14` / Donetsk oblast) | Velikyy Lickon |

All lab-aligned rows share `street: Python-TypeScript`, `house_number: 1`, `postal_code: 01001`. `restricted_UA` restriction is keyed by `country_code` + `region_code` (`UA-14`), not city name.

## When porto-data changes

1. Check diffs in affected provider catalogs and `policy/`.
2. Update only affected scenarios/fixtures.
3. Run Lab `matrix-orders-sync.py` when wire graph changes.
4. Re-evaluate `canary.yaml` if wire or pricing behavior changed.
