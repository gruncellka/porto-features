# Porto Features Bugbot Rules

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

If a PR adds language-specific step-definition code (for example files in `tests/steps/**`, or new `.py`/`.ts` step glue intended for BDD execution), then:

- Add a blocking Bug titled `Language-specific step definitions added to shared features repo`.
- Body: `This repository stores shared features and fixtures only. Keep step definitions in SDK repositories.`
- Apply labels `structure`, `compatibility`.

### 3) Published feature and fixture assets must live under porto_features/ (blocking)

If a PR adds new shared feature or fixture assets outside `porto_features/features/**` or `porto_features/fixtures/**`, then:

- Add a blocking Bug titled `Shared test asset added outside published package paths`.
- Body: `Place feature and fixture assets under porto_features/ so npm and PyPI publish identical content.`
- Apply labels `packaging`, `release`.

### 4) Feature changes should include validation script updates when needed (non-blocking)

If a PR changes `porto_features/features/**` or `porto_features/fixtures/**` and `scripts/validate_features.py` is not updated when validation rules appear affected, then:

- Add a non-blocking Bug titled `Feature/fixture change may need validator update`.
- Body: `Confirm that scripts/validate_features.py still validates the new scenario or fixture patterns, and update it if needed.`
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
