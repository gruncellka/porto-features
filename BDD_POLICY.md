# Porto Features: Economical BDD Coverage Strategy

This guide defines how we design `.feature` scenarios and fixtures to keep Porto Kasse credit usage low while still covering all critical behavior.

## Goal

- Keep API-paid tests minimal and intentional.
- Keep behavior coverage complete across products, zones, weight logic, services, and restrictions.
- Make feature files compact, deterministic, and easy to maintain.

## Confidence ratio (explicit policy)

Confidence ratio is how we split trust-building tests between offline logic and online API integration:

- **Offline target:** 90-95% of scenarios
- **Online target:** 5-10% of scenarios

### What 90-95% offline means in practice

Almost all business rules must be verifiable without paid API calls. If Porto API is unavailable, most tests should still pass.

Offline must cover:

- Product resolution
- Zone resolution
- Weight tier selection
- Service availability rules
- Restriction classification
- Payload construction
- Price lookup logic
- Error mapping logic

### What 5-10% online means in practice

Online scenarios validate integration health, not core business logic:

- Authentication and token generation
- API payload acceptance
- Stamp generation
- Response parsing
- Detection of API-side validation/rule changes

## What porto-data tells us (source of truth)

Based on `resources/porto-data/porto_data/data`:

- Products: `letter_standard`, `letter_compact`, `letter_large`, `letter_maxi`, `merchandise`
- Primary supported zones in `data_links.json`: `domestic`, `zone_1_eu`, `world` (plus `zone_2_europe` exists in `zones.json` and should still be validated in resolution behavior)
- Active price dimensions in lookup: `product_id + zone + weight_tier`
- Core weight tiers for letter and merchandise flow: `W0020`, `W0050`, `W0500`, `W1000`, `W2000`
- Registered services in links: `registered_mail`, `registered_mail_mailbox`, `registered_mail_return_receipt`, `registered_mail_personal`, `registered_mail_personal_return_receipt`
- Restrictions dataset is large and volatile; we should test representative statuses, not brute-force all entries.

## Terminology standard (English + real Deutsche Post terms)

Use this convention across features and fixtures:

- Human-readable text should be English first.
- Keep canonical API/data identifiers unchanged (`letter_compact`, `registered_mail`, `zone_1_eu`, etc.).
- When a Deutsche Post term matters, show it as an alias in parentheses on first mention.

Examples for products:

- `letter_standard` -> Standard letter (Deutsche Post: Standardbrief)
- `letter_compact` -> Compact letter (Deutsche Post: Kompaktbrief)
- `letter_large` -> Large letter (Deutsche Post: Großbrief)
- `letter_maxi` -> Maxi letter (Deutsche Post: Maxibrief)
- `merchandise` -> Merchandise shipment (Deutsche Post: Warensendung)

Examples for services:

- `registered_mail` -> Registered mail (Deutsche Post: Einschreiben)
- `registered_mail_mailbox` -> Registered mail mailbox delivery (Deutsche Post: Einschreiben Einwurf)
- `registered_mail_return_receipt` -> Registered mail with return receipt (Deutsche Post: Einschreiben Rückschein)

Scenario naming rule:

- Prefer: `Calculate price for compact letter (Kompaktbrief)`
- Avoid: German-only scenario titles without API id context.

## Always-use principles

1. **Offline first, online second**
   - Default every scenario to offline if behavior can be validated from fixtures/data rules.
   - Use online API only for a small confidence set and for end-to-end integration checks.

2. **One scenario, one behavior**
   - Each scenario should prove one business rule only.
   - Avoid multi-purpose scenarios that increase maintenance cost and hide failures.

3. **Pairwise over cartesian**
   - Do not test every product x zone x service x weight combination online.
   - Use pairwise coverage for combinations, plus explicit boundary scenarios.

4. **Boundary-heavy design**
   - Spend scenarios on tier boundaries and invalid edges (weight and dimensions), not mid-range duplicates.

5. **Representative restriction sampling**
   - Cover each restriction status class (`prohibited`, `severely_restricted`, `restricted`, `limited`, `operational`) with stable examples.
   - Do not attempt full-country exhaustive tests in BDD features.

6. **Data-driven traceability**
   - Every scenario should map to at least one key in `products.json`, `prices.json`, `services.json`, `zones.json`, or `restrictions.json`.
   - Prefer scenario names that include product/zone intent.

## Recommended scenario architecture

### A) Offline contract suite (default in PRs)

Must cover:

- Product resolution for all 5 product types.
- Zone resolution across `domestic`, `zone_1_eu`, `zone_2_europe`, `world`.
- Price lookup correctness using `product_id + zone + weight_tier`.
- Weight boundary tests at transitions:
  - 20/21g
  - 50/51g
  - 500/501g
  - 1000/1001g
- Service availability and feature mapping for each registered service id.
- Restriction behavior for representative statuses and at least one disputed/partial region case.

### B) Online paid suite (financially controlled)

Porto API usage is a financial operation. Paid scenarios must be explicitly bounded and intentional.

## Revised CI strategy for paid Porto API usage

### 1) PR pipeline (default)

- Run full offline suite.
- Do not run paid matrix scenarios.
- Allow exactly one paid canary scenario only via manual trigger:
  - domestic happy-path stamp generation
  - validates auth, payload acceptance, stamp creation, and response parsing

### 2) Nightly pipeline (safe health check)

Nightly must not generate paid stamps by default.

Nightly should only:

- verify authentication/token generation
- check account balance endpoint
- optionally run non-purchase validation endpoints (if available)
- fail when balance is below the configured safety threshold

Nightly is health-check coverage, not paid regression coverage.

### 3) Release pipeline (final integration gate)

Before publishing SDK:

- run extended paid integration tests
- run broader zone/service coverage
- execute matrix tests intentionally
- use release pipeline as final paid integration gate

## Budget safety rules (mandatory)

- No unbounded loops in paid tests.
- Explicit maximum number of paid scenarios per pipeline.
- Balance threshold check before any paid action.
- Paid tests must have deterministic scenario lists (no dynamic fan-out).
- Any exception to paid limits requires explicit maintainer approval.

## Tagging policy for feature files

Use explicit tags to control execution and spend:

- `@offline`
- `@canary`
- `@online`
- `@nightly`
- `@release`

## Fixture strategy (compact but safe)

Build a small canonical fixture pool and reuse it across features:

- `sender_de_valid`
- `recipient_de_domestic`
- `recipient_fr_eu`
- `recipient_ch_zone2`
- `recipient_us_world`
- `recipient_restricted_example` (stable country from restrictions dataset)

For payloads, keep one valid base object per product family and mutate only the field needed for each rule (weight, country, service, dimensions). This minimizes fixture sprawl and scenario noise.

## Minimal coverage matrix we keep

- Products: 5/5 covered (offline)
- Zones: 4/4 covered in resolution logic (including `zone_2_europe`)
- Weight transitions: all primary tier boundaries covered
- Services: all listed registered service ids covered offline, one representative online
- Restrictions: each status class represented by at least one scenario

This gives broad behavioral coverage with controlled paid API usage.

## Change-management protocol (must follow)

When `porto-data` changes:

1. Check diffs in `products.json`, `prices.json`, `services.json`, `zones.json`, `weight_tiers.json`, `restrictions.json`, and `data_links.json`.
2. Update only affected scenarios/fixtures.
3. Verify every new id/value has at least one scenario reference.
4. Re-evaluate paid smoke set if pricing/service behavior changed.

## Techniques that fit this project best

- Risk-based BDD slicing (offline critical rules, paid API smoke only)
- Pairwise combination selection
- Boundary value analysis for weight/dimensions
- Representative equivalence classes for restrictions
- Intentional release-gated full-matrix integration runs instead of per-PR exhaustive runs

## Strategic goal

Protect:

- API integration stability
- SDK behavior contracts
- Porto Kasse budget
- CI predictability

We prioritize financial control and deterministic testing over exhaustive paid validation.
