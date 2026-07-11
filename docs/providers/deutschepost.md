# Deutsche Post scenario notes

**Provider id:** `deutschepost` · **Country:** DE · **Primary adapter:** `internetmarke`

## `@sdk` coverage

- Resolution: all `porto_id` buckets × zones (`domestic`, `zone_1_eu`, `zone_2_europe`, `world`)
- Services: `einschreiben`, `einschreiben_einwurf`, `einschreiben_rueckschein`
- Delivery hints: domestic `between` 1–2 days, `weekdays` `mon_sat`
- Data access: products, graph, integrations manifest

## `@adapters`

- Stamp generation via Internetmarke (`@adapters`)
- Wire code resolution (`graph.edges.wire.internetmarke`) — keep Examples aligned with generated `orders.generated.yaml`

## Tariff reference

[porto-data providers/deutschepost.md](https://github.com/gruncellka/porto-data/blob/main/docs/providers/deutschepost.md)
