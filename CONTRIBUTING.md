# Contributing to Porto Features

Porto Features is a shared BDD contract package (`.feature` + `.json`) with Python tooling for validation and packaging. Step definitions live in **SDK repositories** — not here.

## Quick start

```bash
make
```

First run creates `venv`, installs dev dependencies, and installs pre-commit hooks. Targets use the venv automatically — no `source` needed.

## What to edit

- Feature files: `porto_features/features/**/*.feature` (`sdk/core/`, `sdk/providers/{id}/`, `adapters/{id}/`)
- Error catalog: `porto_features/errors.json` (authored PORTO_* taxonomy; each SDK builds language bindings)
- Fixtures: `porto_features/fixtures/addresses/**/*.json`
- Docs: `docs/` (`vocabulary.md`, `scenario-policy.md`, `matrix.md` → Lab)

Read first: [docs/vocabulary.md](docs/vocabulary.md) · [docs/scenario-policy.md](docs/scenario-policy.md)

**0.x coordination:** Ship breaking catalog and scenario changes together with aligned porto-data and implementor releases — no version pin file in this repo.

## Daily workflow

1. Edit feature and/or fixture files.
2. Run `make check` (or `make check-error-contracts`) so `@error` Gherkin codes ⊆ `errors.json` and scenario ids are unique.
3. After `@sdk` or wire changes, run `make matrix-sync` from [Porto SDK Lab](https://github.com/gruncellka/porto-sdk-lab) and commit regenerated files under Lab `labs/matrix/`.
4. Run `make quality` and `make test-cov`.
5. Update `CHANGELOG.md` under `[Unreleased]` for behavior-spec changes.
6. Commit (pre-commit runs automatically).

## Most useful commands

| Command | Description |
| ------- | ----------- |
| `make` | venv + hooks (default) |
| `make help` | Show all commands |
| `make check` | features + fixtures + `@error` vs `errors.json` |
| `make quality` | validate + lint + format + type-check |
| `make validate` | Same as `check` |
| `make test-cov` | Tests with >=90% coverage gate |
| `make test-publish` | npm + PyPI smoke test |

## Pull requests

CI runs `make quality` and `make test-cov` only — no clones of porto-data or Porto SDK Lab. Matrix generator drift is checked in [Porto SDK Lab CI](https://github.com/gruncellka/porto-sdk-lab) when submodules are present.

## Releases

`main` is the integration branch. Feature and refactor PRs merge here first.

When `main` is stable (CI green, no known release blockers), cut a **release branch** and publish from that branch. Do not bump the published version or tag while feature work is still landing on `main`.

Packages: npm `@gruncellka/porto-features` · PyPI `gruncellka-porto-features`

**0.x coordination:** For breaking catalog or scenario changes, cut aligned release branches in [porto-data](https://github.com/gruncellka/porto-data) and porto-features (and bump Lab submodule pins) in the same window — no version pin file in this repo.

### Flow

1. **Integrate on `main`** — merge PRs; accumulate changes under `CHANGELOG.md` → `[Unreleased]`; do not tag.
2. **Stabilize** — confirm CI on `main` (`make quality` and `make test-cov` locally if needed). For breaking BDD or matrix changes, run `make matrix-sync-check` from Porto SDK Lab before cutting a release.
3. **Cut a release branch** from the stable commit:

   ```bash
   git checkout main && git pull
   git checkout -b release/x.x.x
   ```

4. **On the release branch only:**
   - Move `CHANGELOG.md` `[Unreleased]` → `[X.Y.Z] - YYYY-MM-DD`
   - `bump2version minor` (or `patch` / `major`) — updates `package.json` and `pyproject.toml`
   - `make quality` and `make test-cov`
5. **Tag and publish** from the release branch:

   ```bash
   git tag vX.Y.Z
   git push origin release/x.x.x
   git push origin vX.Y.Z
   ```

   Tag push triggers `.github/workflows/publish.yml` (npm + PyPI).

6. **Merge the release branch back to `main`** so version files and the finalized changelog live on `main`:

   ```bash
   git checkout main && git merge release/x.x.x
   git push origin main
   ```

`bump2version` has `tag = False` in `.bumpversion.cfg` — tags are always created manually in step 5, never by `bump2version`.

### Naming

| Artifact | Pattern | Example |
| -------- | ------- | ------- |
| Release branch | `release/X.Y.Z` | `release/1.1.1` |
| Git tag | `vX.Y.Z` | `v1.1.1` (must match bumped version) |

### When a release branch is optional

A direct bump + tag on `main` is acceptable only for small, isolated fixes when no other PRs are in flight. Default for breaking or multi-PR releases: use a release branch.

## Contact

- **Issues**: [GitHub Issues](https://github.com/gruncellka/porto-features/issues)
