# Catalog alignment (porto-data)

Scenario authoring reference. Live mapping tables: [porto-data docs/porto_id.md](https://github.com/gruncellka/porto-data/blob/main/docs/porto_id.md).

**0.x coordination:** While packages are `0.x`, ship breaking catalog and scenario changes together in the lab — no separate version pin file in this repo. At `1.x`, expect same-minor compatibility across porto-data, porto-features, and SDKs.

## Bundle layout (current)

| Area | Path |
|------|------|
| Provider registry | `providers.json` |
| Per operator | `providers/<id>/products.json`, `services.json`, `graph.json`, `integration.json`, … |
| Shared policy | `policy/restrictions.json`, `policy/markets.json` |
| Shared formats | `formats/envelopes.json`, `formats/layouts.json` |
| Manifest | `metadata.json`, `mappings.json` |

**Removed / stale:** `data_links.json`, flat `data/` tree, `letter_standard` product ids, `merchandise` product.

## Deutsche Post (`deutschepost`)

| porto_id (input) | Native product `id` | Notes |
|------------------|---------------------|-------|
| `small` | `standardbrief` | All zones |
| `medium` | `kompaktbrief` | |
| `large` | `grossbrief` | |
| `extra_large` | `maxibrief`, `maxibrief_international_heavy` | Disambiguate by zone/weight |

| Service porto_id | Native service `id` |
|------------------|---------------------|
| `registered` | `einschreiben`, `einschreiben_einwurf` |
| `registered_return_receipt` | `einschreiben_rueckschein` |
| `insurance` | `zusatzversicherung` |

## La Poste (`laposte`)

| porto_id | Native product `id` | Notes |
|----------|---------------------|-------|
| `small` | `lettre_verte`, `lettre_recommandee_r_un`, … | Recommandée = product at `small`; disambiguate by delivery preference |

## Swiss Post (`swisspost`)

| porto_id | Native product `id` |
|----------|---------------------|
| `small` | `a_post_standardbrief`, `b_post_standardbrief`, `international_standardbrief` |
| `large` | `a_post_grossbrief`, … |
| `extra_large` | `international_maxibrief` |

## Ukrposhta (`ukrposhta`)

| porto_id | Native product `id` | Zones |
|----------|---------------------|-------|
| `small` | `lyst_standartnyi` | `domestic`, `world` |
| `large` | `dokument` | `domestic` only |

## Zones (Deutsche Post reference)

| Zone | Example country |
|------|-----------------|
| `domestic` | DE |
| `zone_1_eu` | FR |
| `zone_2_europe` | CH |
| `world` | US |

## Feature coverage map

| Feature file | Catalog areas exercised |
|--------------|-------------------------|
| `resolution.feature` | products, zones, weights, graph |
| `pricing.feature` | prices/products.json |
| `services.feature` | services, features |
| `delivery_resolution.feature` | products.delivery[], resolution disambiguation |
| `data_access.feature` | providers, metadata, integrations, envelopes |
| `metadata.feature` | metadata.json, providers.json |
| `product_options.feature` | ambiguous porto_id → native id picks |
| `restrictions.feature` | policy/restrictions.json |
| `stamp_generation.feature` | marks, integrations capabilities, wire (online) |

## Disambiguation

When multiple native products share one `porto_id`, SDK applies rules in [porto-data resolution.md](https://github.com/gruncellka/porto-data/blob/main/docs/resolution.md) — e.g. La Poste `delivery preference is "fastest"` → `lettre_services_plus`.
