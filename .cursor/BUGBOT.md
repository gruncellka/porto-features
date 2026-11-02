# porto-features — Bugbot

Scope: **this repository only**. Agent rules: [features.mdc](rules/features.mdc) · [contribution.mdc](rules/contribution.mdc).

## Blocking

1. **SDK-specific detail in `.feature`** — no class/module/framework names in Gherkin.
2. **Step definitions in this repo** — no `tests/bdd/steps/**` or runner glue.
3. **Assets outside published paths** — only `porto_features/features/**`, `fixtures/**`, `errors.json`, `statuses.json`.
4. **Feature missing `@sdk` or `@adapters`**.
5. **Scope tag `@operator:`** — use `@provider:{id}` (same as SDK `provider`).
6. **Legacy letter input** (`letter_standard`, `STANDARD`, letter `porto_id` buckets, …) — use weight (+ optional envelope or product id); services/features use `kind`.
7. **`@full` / `@release` / `@offline` / `@online` / `@api`** — use `@sdk` / `@adapters` / `@canary` / `@heavy`.
8. **Fake mark simulation** (`mark_simulate`, stamp simulate, hardcoded `simulation: true`).
9. **`@error` without unique `@scenario:` or catalog `PORTO_*`** in `errors.json`.
10. **`contracts/` / package `matrix/` / `features.json` reintroduced**.
11. **Non-canonical Gherkin** (`shipping`/`shipment`, `When I check restrictions`, `When I prepare a mark order`, …) — see `docs/vocabulary.md`.
12. **Address fixtures use `city`** — field is `locality` (UPU / porto-data forms).
13. **Status contract drift** — `@status` values must exist in `statuses.json`; provider-native event codes belong in SDK adapters, not the core feature.

## Non-blocking

14. Feature/fixture change may need validator update (`scripts/validate_*.py`).
15. Fixture broader than scenario needs.
16. Scenario readability regression.
17. Behavior-spec change without `CHANGELOG.md`.
18. Untracked `TODO`/`FIXME` without issue ref.
