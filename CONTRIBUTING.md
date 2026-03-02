# Contributing to Porto Features

Porto Features is a feature/fixture repository (`.feature` + `.json`) with Python tooling for validation and packaging.

## Quick start

1. Clone the repository and enter the project directory.
2. Run:
    ```bash
    make setup
    ```
3. Start making changes. Pre-commit hooks run automatically on every commit.
4. Pushes are protected locally: direct push to `main`/`master` and force-pushes are blocked by a pre-push hook.

`make setup` creates `venv`, installs dev dependencies, and installs pre-commit hooks.

## What to edit

- Feature files: `porto_features/features/*.feature`
- Fixtures: `porto_features/fixtures/**/*.json`

## Daily workflow

1. Edit feature and/or fixture files.
2. Run `make validate-features`.
3. Run `make validate-fixtures`.
4. Run `make quality`.
5. Commit changes.

## Most useful commands

### Make

| Command                  | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| `make help`              | Show all commands                                    |
| `make validate-features` | Validate all `.feature` files (syntax + structure)   |
| `make validate-fixtures` | Validate all `.json` fixtures (syntax + structure)   |
| `make lint-json`         | Lint features with gherlint                          |
| `make format`            | Format Python + fixture JSON                         |
| `make format-code`       | Format Python (`CHECK=1` for check-only)             |
| `make format-json`       | Format fixture JSON (`CHECK=1` for check-only)       |
| `make lint`              | Lint features and Python                             |
| `make type-check`        | Run MyPy                                             |
| `make quality`           | validate + lint + format checks (`CHECK=1`) + type-check |
| `make test-publish`      | Build and verify npm + PyPI artifacts locally        |

## Pre-commit behavior

On commit, hooks can format files and run validation/lint/type-check.

If hooks modify files, re-stage and commit again.
On push, if a protected branch or force push is detected, create/update a feature branch and open a PR.

## Pull requests

1. Create a branch.
2. Run `make setup` once.
3. Ensure commits pass pre-commit checks.
4. Open a PR.

CI runs:

- Feature validation
- Fixture validation
- Gherkin linting
- Python format check (`make format-code CHECK=1`)
- JSON format check (`make format-json CHECK=1`)
- Python lint + type-check

## Releases

### Version bump

Before a release:

1. Update `CHANGELOG.md`.
2. Bump version in both `package.json` and `pyproject.toml` (recommended: `bump2version patch` / `minor` / `major`).

### Publishing

Publish workflow: `.github/workflows/publish.yml`

- Trigger by tag push `v*` (normal release), or
- Run manually via GitHub Actions (`workflow_dispatch`)

Manual dispatch supports `publish_target` (`both`, `npm`, `pypi`) for retry scenarios.

Packages:

- GitHub repo: `gruncellka/porto-features`
- npm: `@gruncellka/porto-features`
- PyPI: `gruncellka-porto-features`

Before tagging, make sure validation CI is green for the exact commit you will release.

## CI links

- Validation workflow: [validation](https://github.com/gruncellka/porto-features/actions/workflows/validation.yml)
- Publish workflow: [publish](https://github.com/gruncellka/porto-features/actions/workflows/publish.yml)

## Contact

- **Issues**: [GitHub Issues](https://github.com/gruncellka/porto-features/issues)
- **E-mail**: build@gruncellka.dev
