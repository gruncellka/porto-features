# Contributing to Porto Features

Porto Features is a shared BDD contract package (`.feature` + `.json`) with Python tooling for validation and packaging. Step definitions live in **SDK repositories** — not here.

## Quick start

```bash
make
```

First run creates `venv`, installs dev dependencies, and installs pre-commit hooks. Targets use the venv automatically — no `source` needed.

## What to edit

- Feature files: `porto_features/features/**/*.feature` (`sdk/`, `adapters/`, root `cli.feature`)
- Matrix index: `porto_features/matrix/*.yaml` (orders sync via Lab `make matrix-orders-sync`)
- Fixtures: `porto_features/fixtures/**/*.json`
- Docs hub: `docs/` (vocabulary, matrix, scenario policy, catalog alignment)

Read first: [docs/README.md](docs/README.md) · [docs/matrix.md](docs/matrix.md) · [docs/vocabulary.md](docs/vocabulary.md) · [docs/scenario-policy.md](docs/scenario-policy.md)

## Daily workflow

1. Edit feature and/or fixture files.
2. Run `make quality` and `make test-cov`.
3. Update `CHANGELOG.md` for behavior-spec changes.
4. Commit (pre-commit runs automatically).

## Most useful commands

| Command | Description |
| ------- | ----------- |
| `make` | venv + hooks (default) |
| `make help` | Show all commands |
| `make quality` | validate + lint + format + type-check |
| `make validate` | Feature + fixture validation |
| `make test-cov` | Tests with >=90% coverage gate |
| `make test-publish` | npm + PyPI smoke test |

## Pull requests

CI runs a single `make quality` + `make test-cov` chain (see `.github/workflows/validation.yml`).

## Releases

1. Update `CHANGELOG.md`.
2. Bump version in `package.json` and `pyproject.toml` (`bump2version patch` / `minor` / `major`).
3. Tag manually on `main`: `git tag vX.Y.Z && git push origin vX.Y.Z`.

Packages: npm `@gruncellka/porto-features` · PyPI `gruncellka-porto-features`

## Contact

- **Issues**: [GitHub Issues](https://github.com/gruncellka/porto-features/issues)
