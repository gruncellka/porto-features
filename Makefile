.PHONY: . help venv install-hooks
.PHONY: features fixtures errors
.PHONY: validate format lint types test artifact

# Prefer Python 3.13+ (project requires >=3.13). Override in CI: PYTHON3=python
PYTHON3 ?= $(shell command -v python3.13 2>/dev/null || command -v python3 2>/dev/null || echo python3)
export PYTHON3

VENV := venv
VENV_PYTHON := $(VENV)/bin/python
VENV_MARKER := $(VENV)/.setup-complete

# Plain `make`
.DEFAULT_GOAL := .

.: venv install-hooks
	@echo "✓ Ready — make targets use venv automatically (no source needed)"

help:
	@echo "Porto Features - Feature Validation & Code Quality"
	@echo "=================================================="
	@echo ""
	@echo "  make               - venv + dev deps + pre-commit hooks (targets use venv automatically)"
	@echo "  make help          - Show this help"
	@echo "  make venv          - Create venv + install dev deps only (CI / scripts)"
	@echo ""
	@echo "Validation leaves (CI 1:1):"
	@echo "  make features      - Gherkin tags, vocabulary, layout"
	@echo "  make fixtures      - Address JSON fixtures"
	@echo "  make errors        - @error scenarios vs errors.json"
	@echo "  make format        - Check Python + JSON formatting (rewrite via pre-commit)"
	@echo "  make lint          - Gherkin + Python"
	@echo "  make types         - Static types"
	@echo "  make test          - Script tests with coverage gate"
	@echo "  make validate      - features + fixtures + errors (contract umbrella)"
	@echo ""
	@echo "Publish:"
	@echo "  make artifact      - build npm+PyPI once, verify, smoke (keeps tarball + dist/)"
	@echo ""

# CI / scripts: setup only — no hooks
venv:
	@if [ ! -x "$(VENV_PYTHON)" ] || [ ! -f "$(VENV_MARKER)" ]; then \
		echo "Setting up porto-features (venv + dev deps)..."; \
		$(PYTHON3) -m venv $(VENV) || (echo "Error: need Python >=3.13 ($(PYTHON3) failed)" && exit 1); \
		. $(VENV)/bin/activate && pip install -q -U pip && pip install -q ".[dev]"; \
		touch $(VENV_MARKER); \
		echo "✓ Ready"; \
	fi

install-hooks: venv
	@if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then \
		echo "Installing pre-commit hooks..."; \
		if [ -f $(VENV)/bin/pre-commit ]; then \
			$(VENV)/bin/pre-commit install --hook-type pre-commit --hook-type pre-push; \
		else \
			echo "Error: pre-commit not found."; \
			exit 1; \
		fi; \
		echo "✓ Pre-commit hooks installed"; \
	fi

# ==========================================
# Umbrella commands
# ==========================================
validate: venv features fixtures errors

format: venv
	@echo "Checking formatting..."
	@. $(VENV)/bin/activate && ruff format --check scripts/ tests/ || (echo "✗ Python is not properly formatted." && exit 1)
	@for file in porto_features/fixtures/addresses/*.json; do \
		if [ -f "$$file" ]; then \
			if $(PYTHON3) -m json.tool "$$file" "$$file.tmp" > /dev/null 2>&1; then \
				if ! cmp -s "$$file" "$$file.tmp"; then \
					echo "✗ $$file is not properly formatted"; \
					rm -f "$$file.tmp"; \
					exit 1; \
				else \
					rm -f "$$file.tmp"; \
				fi; \
			else \
				echo "✗ $$file: Invalid JSON"; \
				rm -f "$$file.tmp"; \
				exit 1; \
			fi; \
		fi; \
	done
	@echo "✓ format"

lint: venv
	@echo "Linting Gherkin and Python..."
	@. $(VENV)/bin/activate && gherlint lint porto_features/features/ || exit 1
	@. $(VENV)/bin/activate && ruff check scripts/ tests/ || exit 1
	@echo "✓ lint"

types: venv
	@echo "Type checking..."
	@. $(VENV)/bin/activate && mypy scripts/
	@echo "✓ types"

# ==========================================
# Validation leaves
# ==========================================
features: venv
	@echo "Validating feature files..."
	@. $(VENV)/bin/activate && python scripts/validate_features.py || exit 1
	@echo "✓ features"

fixtures: venv
	@echo "Validating fixture files..."
	@. $(VENV)/bin/activate && python scripts/validate_fixtures.py || exit 1
	@echo "✓ fixtures"

errors: venv
	@echo "Checking @error scenarios against errors.json..."
	@. $(VENV)/bin/activate && python scripts/validate_error_contracts.py || exit 1
	@echo "✓ errors"

# ==========================================
# Testing
# ==========================================
test: venv
	@echo "Running tests..."
	@. $(VENV)/bin/activate && pytest -q tests/ --cov=scripts --cov-report=term-missing --cov-report=html --cov-report=xml || exit 1
	@echo "✓ test"

# ==========================================
# Publish
# ==========================================
artifact: venv
	@./scripts/release/verify_artifact.sh
