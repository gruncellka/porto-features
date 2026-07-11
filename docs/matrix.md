# Matrix — SDK + adapters coverage index

This package indexes **what** scenarios prove. Implementor test suites decide **when** and **how** to execute them (free `@sdk` in CI; paid `@adapters` with credentials).

## Glossary (one word, one meaning)

| Term | Meaning |
|------|---------|
| **`@sdk`** | Free BDD — resolver, pricing, validation from porto-data |
| **`@adapters`** | Paid BDD — real provider purchase via integration |
| **`@canary` / `@full`** | Adapter sub-tags — smoke vs full wire matrix |
| **`provider`** | Postal operator (`deutschepost`, …) — same as porto-data |
| **`adapter`** | Integration id (`internetmarke`, …) — same as porto-data |
| **`concern`** | Test domain in `cell_id` (`resolution`, `pricing`, …) |
| **`case_id`** | Adapter order cell slug from porto-data wire (`deutschepost.internetmarke.standardbrief.domestic.einschreiben`) |

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
│   sdk/
│   ├── core/                # @sdk @core
│   └── providers/{id}/      # @sdk @operator:{id}
│   adapters/{id}/           # @adapters @operator:{id} @wire:{adapter}
```

## Two layers

| Layer | Tag | Matrix file | Typical cost |
|-------|-----|-------------|--------------|
| SDK | `@sdk` | `sdk.yaml` | Free |
| Adapters | `@adapters` | `orders.generated.yaml` + `canary.yaml` | Paid when executed |

**Order list source of truth:** porto-data `graph.edges.wire.<adapter>`. Generated into `orders.generated.yaml` by Porto SDK Lab `matrix-orders-sync.py`. Paid runs may attach `evidence:` metadata; they do not define new `case_id`s.

## cell_id (SDK layer)

```text
{provider}.{concern}.{slice}.{porto_id}.{zone}
```

Example: `deutschepost.resolution.happy.small.domestic`

## case_id (adapter order cells)

```text
{provider}.{adapter}.{product_id}.{zone_id}[.{service_id}...]
```

Examples:

| case_id | Meaning |
|---------|---------|
| `deutschepost.internetmarke.standardbrief.domestic` | Base domestic standard letter |
| `deutschepost.internetmarke.maxibrief_ausland.world` | International maxi (native id with underscore) |
| `deutschepost.internetmarke.standardbrief.domestic.einschreiben` | Domestic + registered service |

Rules:

- **Dots** separate segments only; `product_id` and `service_id` keep internal underscores as porto-data native ids.
- **At most one** `service_id` per cell today (wire variants) — if multiple later, append each as its own dot segment (sorted).
- **Do not hand-edit** `orders.generated.yaml` — regenerate via Porto SDK Lab `matrix-orders-sync.py`.
- **Do not parse** `case_id` in product code — use structured fields on the order cell; `case_id` is a stable slug and artifact path key.
- **Matrix refs** must name an existing scenario or outline when using `:Scenario:` / `:Outline:` suffixes (enforced by `scripts/validate_features.py`).

## Run lanes (by tag)

| Lane | porto-features artifact | Tag filter |
|------|-------------------------|------------|
| SDK exhaustive | `features/sdk/` + `sdk.yaml` | `@sdk` |
| Adapter canary | `canary.yaml` case_ids | `@adapters` `@canary` |
| Adapter full | all `order_cells` in `orders.generated.yaml` | `@adapters` `@full` |

Implementor runners (Python, TypeScript, or other) load the same `.feature` files and filter by tag.

## Sync orders from porto-data

Wire-derived adapter index is regenerated in [Porto SDK Lab](https://github.com/gruncellka/porto-sdk-lab):

```bash
python scripts/matrix-orders-sync.py
python scripts/matrix-orders-sync.py --check
```

No `porto-features → porto-data` package dependency — sync is a separate tooling step at the Lab boundary.

## Regenerate SDK matrix (`sdk.yaml`)

After adding or renaming `@sdk` scenarios, regenerate the SDK coverage index:

```bash
make generate-sdk-matrix
make generate-sdk-matrix-check   # CI gate — fails on drift
```

Direct script:

```bash
python scripts/generate_sdk_matrix.py
python scripts/generate_sdk_matrix.py --check
```

SDK implementors with large CLI suites should batch BDD by `@operator:{id}` (not one monolithic run) — see `sdk/core/cli.feature` per-provider Rules.
