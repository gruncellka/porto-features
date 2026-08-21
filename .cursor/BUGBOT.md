# Porto Features — Bugbot PR review rules

**Canonical PR review resource** for this repo. Cursor Bugbot reads this file on PR review; agents should follow it when editing `porto_features/` or validation scripts.

**Agent rules (Cursor):** [`.cursor/rules/features-layering-doctrine.mdc`](.cursor/rules/features-layering-doctrine.mdc) · [`.cursor/rules/karpathy-guidelines.mdc`](.cursor/rules/karpathy-guidelines.mdc) · [`.cursor/rules/git-no-auto-commit.mdc`](.cursor/rules/git-no-auto-commit.mdc)

## Scope

- This file defines repository-level review rules for Bugbot in `porto-features`.
- Keep findings focused on SDK-agnostic behavior specs, fixture quality, and publishable package structure.
- Align checks with `.cursorrules` for this repository.
- Treat `porto-features` as an independent package; do not assume direct coupling with other resource packages.
- Review scope is only changes inside this `porto-features` repository.
- Do not raise findings for files, workflows, or policies in other repositories of this workspace.

## Rule format

- Use explicit, actionable findings.
- Use blocking bugs for correctness, cross-SDK compatibility, or packaging risks.
- Use non-blocking bugs for maintainability and coordination risks.

## Rules

### 1) Feature specs must stay SDK-agnostic (blocking)

If a PR adds or changes `.feature` files and introduces SDK-specific implementation details (language-specific classes, method names, internal module paths, or framework internals), then:

- Add a blocking Bug titled `Feature file contains SDK-specific implementation detail`.
- Body: `Gherkin scenarios must describe behavior only and remain shared across Python and TypeScript SDKs. Remove implementation-specific details.`
- Apply labels `compatibility`, `bdd`.

### 2) Step definitions must not be added in this repo (blocking)

If a PR adds language-specific step-definition code (for example files in `tests/bdd/steps/**`, or new `.py`/`.ts` step glue intended for BDD execution), then:

- Add a blocking Bug titled `Language-specific step definitions added to shared features repo`.
- Body: `This repository stores shared features and fixtures only. Keep step definitions in SDK repositories.`
- Apply labels `structure`, `compatibility`.

### 3) Published feature and fixture assets must live under porto_features/ (blocking)

If a PR adds new shared feature, fixture, or catalog assets outside `porto_features/features/**`, `porto_features/fixtures/**`, or `porto_features/errors.json`, then:

- Add a blocking Bug titled `Shared test asset added outside published package paths`.
- Body: `Place features, fixtures, and errors.json under porto_features/ so npm and PyPI publish identical content.`
- Apply labels `packaging`, `release`.

### 4) Feature changes should include validation script updates when needed (non-blocking)

If a PR changes `porto_features/features/**` or `porto_features/fixtures/**` and `scripts/validate_features.py` or `scripts/validate_error_contracts.py` is not updated when validation rules appear affected, then:

- Add a non-blocking Bug titled `Feature/fixture change may need validator update`.
- Body: `Confirm that scripts/validate_features.py and scripts/validate_error_contracts.py still validate the new scenario or fixture patterns, and update them if needed.`
- Apply label `quality`.

### 5) Fixtures should stay scenario-focused and stable (non-blocking)

If a PR adds large or overly broad fixture payloads where smaller scenario-specific examples would be clearer, then:

- Add a non-blocking Bug titled `Fixture scope may be broader than needed`.
- Body: `Keep fixtures focused on BDD scenario intent, readable, and stable over time. Prefer minimal examples that support the behavior under test.`
- Apply label `maintainability`.

### 6) Scenario readability and BDD shape should be enforced (non-blocking)

If new scenarios are difficult to follow (for example missing clear Given/When/Then flow or unclear business intent), then:

- Add a non-blocking Bug titled `Scenario readability regression`.
- Body: `Rewrite scenarios to keep business intent clear and preserve Given/When/Then readability.`
- Apply label `bdd`.

### 7) Changelog should track behavior-spec changes (non-blocking)

If a PR changes shared behavior files in `porto_features/features/**` and does not update `CHANGELOG.md`, then:

- Add a non-blocking Bug titled `Behavior spec changed without changelog update`.
- Body: `Consider documenting behavior-spec changes in CHANGELOG.md for SDK maintainers and consumers.`
- Apply label `release-notes`.

### 8) TODO/FIXME comments must be tracked (non-blocking)

If changed files include `TODO` or `FIXME` without an issue reference like `#123` or `ABC-123`, then:

- Add a non-blocking Bug titled `Untracked TODO/FIXME comment`.
- Body: `Link TODO/FIXME to a tracked issue (for example TODO(#123): ...) or remove it.`
- Apply label `maintainability`.

### 9) Feature files must declare layer tags (blocking)

If a PR adds or changes `.feature` files and the Feature lacks `@sdk` or `@adapters`, then:

- Add a blocking Bug titled `Feature missing @sdk or @adapters tag`.
- Body: `Every Feature must declare exactly one of @sdk or @adapters at Feature level. Paid adapter Examples must align with generated wire rows. See docs/scenario-policy.md and docs/matrix.md.`
- Apply labels `bdd`, `quality`.

### 10) SDK input must use porto_id vocabulary (blocking)

If a PR uses legacy product tokens as SDK input — for example `letter_standard`, `letter_compact`, `STANDARD`, `COMPACT`, `MERCHANDISE`, or `the letter type is` with enum names instead of `porto_id` buckets (`small`, `medium`, `large`, `extra_large`) — then:

- Add a blocking Bug titled `Legacy product vocabulary in feature scenario`.
- Body: `SDK input uses porto_id size buckets. Native product id belongs in Then assertions only. See docs/vocabulary.md.`
- Apply labels `compatibility`, `bdd`.

### 11) Feature files must not reference SDK implementation (blocking)

If a PR names SDK classes (`LetterType`, `PortoClient`, module paths), internal resolver methods, or language-specific types in `.feature` files, then:

- Add a blocking Bug titled `SDK implementation detail in Gherkin`.
- Body: `Scenarios describe behavior only. Step definitions in SDK repos map vocabulary to implementation.`
- Apply labels `compatibility`, `bdd`.

### 12) Paid adapter tags are @canary / @heavy (blocking)

If a PR adds or keeps `@full` or `@release` on adapter scenarios, then:

- Add a blocking Bug titled `Removed adapter tag @full or @release`.
- Body: `Paid lane tags are @canary (smoke) and @heavy (wire matrix). Historical: @release → @full → @heavy. See docs/scenario-policy.md.`
- Apply labels `bdd`, `quality`.

### 13) Do not add fake mark simulation (blocking)

If a PR adds `mark_simulate`, `stamp_generation`, CLI `stamp simulate`, or `When I simulate stamp generation` (hardcoded `simulation: true` after resolve/prepare, no PortoMark), then:

- Add a blocking Bug titled `Fake mark simulation is not a contract`.
- Body: `Offline resolve belongs in resolution.feature. Paid purchase is When I create a mark on adapters/.../marks.feature.`
- Apply labels `bdd`, `quality`.

### 14) @error scenarios need unique @scenario: and a catalog PORTO_* (blocking)

If a PR adds or changes `@error` scenarios without a unique `@scenario:` id or without a `PORTO_*` code declared in `porto_features/errors.json`, then:

- Add a blocking Bug titled `Error scenario missing unique id or catalog code`.
- Body: `Each @error scenario needs @scenario:{id} unique across features and a PORTO_* step that exists in errors.json. Run make check-error-contracts.`
- Apply labels `bdd`, `quality`.

### 15) Do not ship contracts/ or matrix/ in this package (blocking)

If a PR adds `porto_features/contracts/`, `porto_features/matrix/`, or `porto_features/features.json` as published package content, then:

- Add a blocking Bug titled `Removed package path reintroduced`.
- Body: `Published paths are errors.json, features/, and fixtures/. Lab coverage indexes live in Porto SDK Lab labs/matrix/.`
- Apply labels `packaging`, `release`.

### 16) Gherkin uses letter behavior vocabulary (blocking)

If a PR adds `shipping`, `shipment`, `When I check restrictions`, `When I access` catalog steps, `When I prepare a mark order`, `When I calculate the price`, or `When I resolve the shipping configuration` in `.feature` files, then:

- Add a blocking Bug titled `Non-canonical Gherkin vocabulary`.
- Body: `Use letter / price / mailing requirements. Resolve with When I resolve the letter. Catalog inspection is When I inspect … data. Paid errors use When I attempt to create a mark. See docs/vocabulary.md.`
- Apply labels `bdd`, `quality`.
