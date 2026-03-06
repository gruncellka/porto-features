.PHONY: help setup install-hooks
.PHONY: validate-features validate-fixtures lint-json format-code format-json lint-code type-check
.PHONY: format lint quality test test-cov test-coverage test-publish

help: ## Show this help message
	@echo "Porto Features - Feature Validation & Code Quality"
	@echo "=================================================="
	@echo ""
	@echo "Setup:"
	@echo "  make setup         - Install dependencies and pre-commit hooks"
	@echo "  make install-hooks - Install pre-commit hooks"
	@echo ""
	@echo "Quality Checks :"
	@echo "  make quality       - Run all quality checks in read-only mode for CI gates"
	@echo "  make validate-features - Validate all feature files"
	@echo "  make validate-fixtures - Validate all fixture files"
	@echo ""
	@echo "JSON commands:"
	@echo "  make lint-json     - Lint feature files with gherlint"
	@echo "  make format-json   - Format fixture JSON files (CHECK=1 for check-only)"
	@echo ""
	@echo "Code commands:"
	@echo "  make lint-code     - Lint Python code with ruff"
	@echo "  make format-code   - Format Python code with ruff (CHECK=1 for check-only)"
	@echo ""
	@echo "Combined commands:"
	@echo "  make lint          - Lint features and Python code"
	@echo "  make format        - Format Python and JSON files"
	@echo ""
	@echo "Type Checking:"
	@echo "  make type-check    - Type check Python code with mypy"
	@echo ""
	@echo "Tests:"
	@echo "  make test          - Run unit tests for scripts"
	@echo "  make test-cov      - Run tests with coverage gate (>=90%)"
	@echo ""
	@echo "Publish:"
	@echo "  make test-publish  - Pack npm tarball + install and test; build wheel + install and test Python"

# ==========================================
# Setup
# ==========================================

setup: ## Install dependencies and pre-commit hooks
	@echo "Setting up porto-features..."
	@python3.13 -m venv venv
	@. venv/bin/activate && pip install -q -e ".[dev]"
	@if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then \
		$(MAKE) install-hooks || echo "Warning: Could not install pre-commit hooks. Run 'make install-hooks' manually."; \
	else \
		echo "Skipping hook installation (not a git repository)"; \
	fi
	@echo "✓ Setup complete - run 'make help' for commands"

install-hooks: ## Install pre-commit hooks
	@if [ -f venv/bin/pre-commit ]; then \
		venv/bin/pre-commit install --hook-type pre-commit --hook-type pre-push; \
	else \
		python3.13 -m pre_commit install --hook-type pre-commit --hook-type pre-push; \
	fi

# ==========================================
# Quality Checks
# ==========================================

quality: ## Run all quality checks (read-only formatting gates)
	@$(MAKE) validate-features
	@$(MAKE) validate-fixtures
	@$(MAKE) lint-json
	@$(MAKE) format-json CHECK=1
	@$(MAKE) lint-code
	@$(MAKE) format-code CHECK=1
	@$(MAKE) type-check

validate-features: ## Validate all feature files
	@echo "Validating feature files..."
	@if [ -f venv/bin/python ]; then \
		venv/bin/python scripts/validate_features.py || (echo "✗ Feature validation failed." && exit 1); \
	else \
		python3.13 scripts/validate_features.py || (echo "✗ Feature validation failed." && exit 1); \
	fi
	@echo "✓ Feature validation complete"

validate-fixtures: ## Validate all fixture files
	@echo "Validating fixture files..."
	@if [ -f venv/bin/python ]; then \
		venv/bin/python scripts/validate_fixtures.py || (echo "✗ Fixture validation failed." && exit 1); \
	else \
		python3.13 scripts/validate_fixtures.py || (echo "✗ Fixture validation failed." && exit 1); \
	fi
	@echo "✓ Fixture validation complete"

# ==========================================
# JSON Commands
# ==========================================

lint-json: ## Lint feature files with gherlint
	@echo "Linting feature files..."
	@if [ -f venv/bin/gherlint ]; then \
		venv/bin/gherlint lint porto_features/features/ || (echo "✗ Feature linting failed." && exit 1); \
	else \
		gherlint lint porto_features/features/ || (echo "✗ Feature linting failed." && exit 1); \
	fi
	@echo "✓ Feature linting complete"

format-json: ## Format fixture JSON files (CHECK=1 for check-only)
	@if [ -n "$(CHECK)" ]; then echo "Checking JSON formatting..."; else echo "Formatting JSON files..."; fi
	@for file in porto_features/fixtures/addresses/*.json; do \
		if [ -f "$$file" ]; then \
			if python3 -m json.tool "$$file" "$$file.tmp" > /dev/null 2>&1; then \
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

lint-code: ## Lint Python code with ruff
	@echo "Linting Python code..."
	@if [ -f venv/bin/ruff ]; then \
		venv/bin/ruff check scripts/ || (echo "✗ Code linting failed. Fix issues before committing." && exit 1); \
	else \
		ruff check scripts/ || (echo "✗ Code linting failed. Fix issues before committing." && exit 1); \
	fi
	@echo "✓ Code linting complete"

format-code: ## Format Python code with ruff (CHECK=1 for check-only)
	@echo "Running Python formatter..."
	@if [ -f venv/bin/ruff ]; then \
		if [ "$(CHECK)" = "1" ]; then \
			venv/bin/ruff format --check scripts/ || (echo "✗ Python code is not properly formatted. Run 'make format-code' to fix." && exit 1); \
			venv/bin/ruff check scripts/ || (echo "✗ Ruff checks failed. Run 'make format-code' locally to auto-fix where possible." && exit 1); \
		else \
			venv/bin/ruff format scripts/ || (echo "✗ Failed to format code with ruff" && exit 1); \
			venv/bin/ruff check --fix scripts/ || (echo "✗ Failed to fix linting issues with ruff" && exit 1); \
		fi; \
	else \
		if [ "$(CHECK)" = "1" ]; then \
			ruff format --check scripts/ || (echo "✗ Python code is not properly formatted. Run 'make format-code' to fix." && exit 1); \
			ruff check scripts/ || (echo "✗ Ruff checks failed. Run 'make format-code' locally to auto-fix where possible." && exit 1); \
		else \
			ruff format scripts/ || (echo "✗ Failed to format code with ruff" && exit 1); \
			ruff check --fix scripts/ || (echo "✗ Failed to fix linting issues with ruff" && exit 1); \
		fi; \
	fi
	@echo "✓ Python formatting complete"

# ==========================================
# Combined Commands
# ==========================================

lint: lint-json lint-code ## Lint features and Python code

format: format-code format-json ## Format Python and JSON files

# ==========================================
# Type Checking
# ==========================================

type-check: ## Type check Python code with mypy
	@echo "Type checking Python code..."
	@if [ -f venv/bin/mypy ]; then \
		venv/bin/mypy scripts/ || (echo "✗ Type checking failed." && exit 1); \
	else \
		mypy scripts/ || (echo "✗ Type checking failed." && exit 1); \
	fi
	@echo "✓ Type check complete"

# ==========================================
# Tests
# ==========================================

test: ## Run unit tests for scripts
	@echo "Running unit tests..."
	@if [ -f venv/bin/pytest ]; then \
		venv/bin/pytest -q tests/ || (echo "✗ Tests failed." && exit 1); \
	else \
		pytest -q tests/ || (echo "✗ Tests failed." && exit 1); \
	fi
	@echo "✓ Tests passed"

test-cov: ## Run tests with coverage gate (>=90%)
	@echo "Running tests with coverage..."
	@if [ -f venv/bin/pytest ]; then \
		venv/bin/pytest -q tests/ --cov=scripts --cov-report=term-missing --cov-report=html --cov-report=xml --cov-fail-under=90 || (echo "✗ Coverage check failed." && exit 1); \
	else \
		pytest -q tests/ --cov=scripts --cov-report=term-missing --cov-report=html --cov-report=xml --cov-fail-under=90 || (echo "✗ Coverage check failed." && exit 1); \
	fi
	@echo "✓ Coverage check passed"

test-coverage: test-cov ## Alias for coverage gate

# ==========================================
# Publish
# ==========================================

test-publish: ## Pack npm + build wheel and verify both install and work
	@./tests/test_publish.sh
