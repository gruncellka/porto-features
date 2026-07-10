# Matrix — SDK + adapters coverage index

porto-features defines **what** to prove. Lab defines **when** and **how** to run paid cases (see Porto SDK Lab `docs/labs/LAB_BOUNDARIES.md`).

## Glossary (one word, one meaning)

| Term | Meaning |
|------|---------|
| **`@sdk`** | Free BDD — resolver, pricing, validation from porto-data; runs in SDK PR CI |
| **`@adapters`** | Paid BDD — real Portokasse purchase via provider integration |
| **`@canary` / `@full`** | Adapter sub-tags — daily smoke vs weekly full matrix |
| **`provider`** | Postal operator (`deutschepost`, …) — same as porto-data |
| **`adapter`** | Integration id (`internetmarke`, …) — same as porto-data |
| **`concern`** | SDK test domain in `cell_id` (`resolution`, `pricing`, …) |
| **`case_id`** | Adapter order cell from porto-data wire (`standardbrief_domestic_einschreiben`) |

Rejected tags: `@offline`, `@online`, `@api`, `@capabilities`, `@features`.

## Layout

```text
porto_features/
├── matrix/
│   slices.yaml              # slice taxonomy
│   sdk.yaml                 # layer A index (hand)
│   canary.yaml              # daily paid case_ids (hand, ⊆ orders)
│   orders.generated.yaml    # layer B — from porto-data wire only
├── features/
│   sdk/                     # @sdk
│   adapters/                # @adapters
│   cli.feature
```

## Two layers

| Layer | Tag | Matrix file | Pays? |
|-------|-----|-------------|-------|
| SDK | `@sdk` | `sdk.yaml` | No |
| Adapters | `@adapters` | `orders.generated.yaml` + `canary.yaml` | Yes |

**Order list source of truth:** porto-data `graph.edges.wire.<adapter>` — synced by Lab `scripts/matrix-orders-sync.py`. Lab runs attach `evidence:` only; they never add `case_id`s.

## cell_id (SDK layer)

```text
{provider}.{concern}.{slice}.{porto_id}.{zone}
```

Example: `deutschepost.resolution.happy.small.domestic`

## Three run lanes

| Lane | porto-features | Who runs |
|------|----------------|----------|
| SDK exhaustive | `features/sdk/` + `sdk.yaml` | SDK CI (`@sdk`) |
| Adapter canary | `canary.yaml` + `@adapters @canary` | Lab cron (daily) |
| Adapter full | all `order_cells` + `@adapters @full` | Lab cron (weekly) |

## Sync orders from porto-data (Lab only)

```bash
# From Porto SDK Lab root
python scripts/matrix-orders-sync.py
python scripts/matrix-orders-sync.py --check
```

No `porto-features → porto-data` package dependency — sync runs at Lab boundary.
