.PHONY: . help venv install-hooks
.PHONY: validate-features validate-fixtures lint-gherlint format-json format-code lint-code type-check
.PHONY: check-error-contracts check
.PHONY: validate format lint quality test test-cov test-coverage test-publish

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
	@echo "Most Common Commands:"
	@echo "  make check         - Alias for validate (features, fixtures, error contracts)"
	@echo "  make quality       - validate + format + lint + type-check"
	@echo "  make validate      - Validate features, fixtures, error contracts"
	@echo "  make format        - Format Python and JSON"
	@echo "  make lint          - Lint features and Python"
	@echo ""
	@echo "Feature Commands:"
	@echo "  make validate-features - Validate all .feature files"
	@echo "  make validate-fixtures - Validate all fixture JSON files"
	@echo "  make check-error-contracts - @error ⊆ errors.json; unique scenario ids"
	@echo "  make lint-gherlint     - Lint Gherkin with gherlint"
	@echo ""
	@echo "JSON Commands:"
	@echo "  make format-json    - Format fixture JSON (CHECK=1 for read-only)"
	@echo ""
	@echo "Code Commands:"
	@echo "  make format-code    - Ruff format (CHECK=1 for read-only)"
	@echo "  make lint-code      - Ruff lint"
	@echo "  make type-check     - MyPy"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run tests"
	@echo "  make test-cov       - Tests with coverage gate (>=90%)"
	@echo ""
	@echo "Publish:"
	@echo "  make test-publish   - npm + PyPI install smoke test"
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
# Most Common Commands
# ==========================================
validate: venv validate-features validate-fixtures check-error-contracts

check: validate

format: venv format-code format-json

lint: venv lint-gherlint lint-code

quality: venv validate lint format type-check

# ==========================================
# Feature Commands
# ==========================================
validate-features: venv
	@echo "Validating feature files..."
	@. $(VENV)/bin/activate && python scripts/validate_features.py || (echo "✗ Feature validation failed." && exit 1)
	@echo "✓ Feature validation complete"

validate-fixtures: venv
	@echo "Validating fixture files..."
	@. $(VENV)/bin/activate && python scripts/validate_fixtures.py || (echo "✗ Fixture validation failed." && exit 1)
	@echo "✓ Fixture validation complete"

check-error-contracts: venv
	@echo "Checking @error scenarios against errors.json..."
	@. $(VENV)/bin/activate && python scripts/validate_error_contracts.py || (echo "✗ Error contracts mismatch." && exit 1)
	@echo "✓ Error contract check complete"

lint-gherlint: venv
	@echo "Linting feature files..."
	@. $(VENV)/bin/activate && gherlint lint porto_features/features/ || (echo "✗ Feature linting failed." && exit 1)
	@echo "✓ Feature linting complete"

# ==========================================
# JSON Commands
# ==========================================
format-json:
	@if [ -n "$(CHECK)" ]; then echo "Checking JSON formatting..."; else echo "Formatting JSON files..."; fi
	@for file in porto_features/fixtures/addresses/*.json; do \
		if [ -f "$$file" ]; then \
			if $(PYTHON3) -m json.tool "$$file" "$$file.tmp" > /dev/null 2>&1; then \
				if ! cmp -s "$$file" "$$file.tmp"; then \
					if [ -n "$(CHECK)" ]; then \
						echo "✗ $$file is not properly formatted"; \
						rm -f "$$file.tmp"; \
						exit 1; \
					fi; \
					if mv "$$file.tmp" "$$file"; then \
						echo "✓ Formatted $$file"; \
					else \
						echo "✗ $$file: Failed to move formatted file"; \
						rm -f "$$file.tmp"; \
						exit 1; \
					fi; \
				else \
					rm -f "$$file.tmp" && echo "✓ $$file (already formatted)"; \
				fi; \
			else \
				echo "✗ $$file: Invalid JSON - cannot format"; \
				rm -f "$$file.tmp"; \
				exit 1; \
			fi; \
		fi; \
	done
	@if [ -n "$(CHECK)" ]; then echo "✓ All JSON files are properly formatted"; else echo "✓ All JSON files formatted"; fi

# ==========================================
# Code Commands
# ==========================================
format-code: venv
	@if [ -n "$(CHECK)" ]; then \
		echo "Checking Python code formatting..."; \
		. $(VENV)/bin/activate && ruff format --check scripts/ tests/ || (echo "✗ Code is not properly formatted. Run 'make format-code' to fix." && exit 1); \
		echo "✓ Code formatting check complete"; \
	else \
		echo "Formatting Python code..."; \
		. $(VENV)/bin/activate && ruff format scripts/ tests/ || (echo "✗ Failed to format code with ruff" && exit 1); \
		. $(VENV)/bin/activate && ruff check --fix scripts/ tests/ || (echo "✗ Failed to fix linting issues with ruff" && exit 1); \
		echo "✓ Code formatted"; \
	fi

lint-code: venv
	@echo "Linting Python code..."
	@. $(VENV)/bin/activate && ruff check scripts/ tests/ || (echo "✗ Code linting failed. Fix issues before committing." && exit 1)
	@echo "✓ Code linting complete"

type-check: venv
	@echo "Type checking Python code..."
	@. $(VENV)/bin/activate && mypy scripts/
	@echo "✓ Type check complete"

# ==========================================
# Testing
# ==========================================
test: venv
	@echo "Running unit tests..."
	@. $(VENV)/bin/activate && pytest -q tests/ || (echo "✗ Tests failed." && exit 1)
	@echo "✓ Tests passed"

test-cov: venv
	@echo "Running tests with coverage..."
	@. $(VENV)/bin/activate && pytest -q tests/ --cov=scripts --cov-report=term-missing --cov-report=html --cov-report=xml --cov-fail-under=90 || (echo "✗ Coverage check failed." && exit 1)
	@echo "✓ Coverage check passed"

test-coverage: test-cov

# ==========================================
# Publish
# ==========================================
test-publish: venv
	@./tests/test_publish.sh
