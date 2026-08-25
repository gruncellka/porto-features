# porto-features — Bugbot

Scope: **this repository only**. Agent rules: [features.mdc](rules/features.mdc) · [contribution.mdc](rules/contribution.mdc).

## Blocking

1. **SDK-specific detail in `.feature`** — no class/module/framework names in Gherkin.
2. **Step definitions in this repo** — no `tests/bdd/steps/**` or runner glue.
3. **Assets outside published paths** — only `porto_features/features/**`, `fixtures/**`, `errors.json`.
4. **Feature missing `@sdk` or `@adapters`**.
5. **Legacy product input** (`letter_standard`, `STANDARD`, letter `porto_id` buckets, …) — use weight (+ optional envelope or product id).
6. **`@full` / `@release`** — use `@canary` / `@heavy`.
7. **Fake mark simulation** (`mark_simulate`, stamp simulate, hardcoded `simulation: true`).
8. **`@error` without unique `@scenario:` or catalog `PORTO_*`** in `errors.json`.
9. **`contracts/` / package `matrix/` / `features.json` reintroduced**.
10. **Non-canonical Gherkin** (`shipping`/`shipment`, `When I check restrictions`, `When I prepare a mark order`, …) — see `docs/vocabulary.md`.

## Non-blocking

11. Feature/fixture change may need validator update (`scripts/validate_*.py`).
12. Fixture broader than scenario needs.
13. Scenario readability regression.
14. Behavior-spec change without `CHANGELOG.md`.
15. Untracked `TODO`/`FIXME` without issue ref.
