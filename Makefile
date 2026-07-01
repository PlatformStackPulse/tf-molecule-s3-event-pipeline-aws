# =============================================================================
# Terraform Module — Makefile
# =============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Load .env if present (does not override existing env vars)
-include .env
export

# Terraform settings (override via .env or environment)
TF_VERSION     ?= 1.11.3
TFLINT_VERSION ?= v0.53.0
TRIVY_VERSION  ?= 0.58.0
TF_REFRESH     ?= true
TF_UPGRADE     ?= false
EXAMPLES_DIR   := examples
TESTS_DIR      := tests

# Computed flags from settings
TF_INIT_FLAGS  := -backend=false -input=false
ifeq ($(TF_UPGRADE),true)
  TF_INIT_FLAGS += -upgrade
endif

TF_CMD_FLAGS   :=
ifeq ($(TF_REFRESH),false)
  TF_CMD_FLAGS += -refresh=false
endif

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
RESET  := \033[0m

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(CYAN)Terraform Module$(RESET)"
	@echo ""
	@echo "$(GREEN)Core Targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Core Targets
# =============================================================================

.PHONY: init
init: ## Initialize the module (honours TF_UPGRADE)
	@echo "$(GREEN)Initializing module...$(RESET)"
	@terraform init $(TF_INIT_FLAGS) > /dev/null 2>&1
	@echo "$(GREEN)✓ Module initialized$(RESET)"

.PHONY: init-upgrade
init-upgrade: ## Initialize with -upgrade (force latest providers/modules)
	@echo "$(GREEN)Initializing module (upgrade)...$(RESET)"
	@terraform init -backend=false -input=false -upgrade
	@echo "$(GREEN)✓ Module initialized (providers upgraded)$(RESET)"

.PHONY: fmt
fmt: ## Format all Terraform files
	@echo "$(GREEN)Formatting...$(RESET)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Formatted$(RESET)"

.PHONY: fmt-check
fmt-check: ## Check formatting (CI mode — fails on diff)
	@echo "$(GREEN)Checking format...$(RESET)"
	@terraform fmt -check -recursive -diff
	@echo "$(GREEN)✓ Format OK$(RESET)"

.PHONY: validate
validate: init ## Validate the module
	@echo "$(GREEN)Validating module...$(RESET)"
	@terraform validate
	@echo "$(GREEN)✓ Module valid$(RESET)"

.PHONY: lint
lint: ## Run TFLint
	@echo "$(GREEN)Linting...$(RESET)"
	@tflint --init > /dev/null 2>&1
	@tflint
	@echo "$(GREEN)✓ Lint OK$(RESET)"

.PHONY: test
test: test-unit ## Run all tests

.PHONY: test-unit
test-unit: init ## Run unit tests
	@echo "$(GREEN)Running unit tests...$(RESET)"
	@terraform test -test-directory=$(TESTS_DIR)/unit -verbose
	@echo "$(GREEN)✓ Unit tests passed$(RESET)"

.PHONY: test-integration
test-integration: init ## Run integration tests (requires AWS credentials)
	@echo "$(YELLOW)Running integration tests (requires AWS credentials)...$(RESET)"
	@terraform test -test-directory=$(TESTS_DIR)/integration -verbose
	@echo "$(GREEN)✓ Integration tests passed$(RESET)"

.PHONY: security
security: ## Run Trivy IaC security scan
	@echo "$(GREEN)Running security scan...$(RESET)"
	@trivy config . --severity HIGH,CRITICAL --tf-exclude-downloaded-modules
	@echo "$(GREEN)✓ Security scan passed$(RESET)"

.PHONY: docs
docs: ## Generate terraform-docs
	@echo "$(GREEN)Generating documentation...$(RESET)"
	@terraform-docs markdown table --output-file README.md --output-mode inject .
	@echo "$(GREEN)✓ Documentation generated$(RESET)"

.PHONY: clean
clean: ## Remove .terraform dirs and plan files
	@echo "$(GREEN)Cleaning...$(RESET)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@find . -type f -name "*.tfplan.txt" -delete 2>/dev/null || true
	@rm -rf .plans/ 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(RESET)"

# =============================================================================
# Build Targets
# =============================================================================

.PHONY: all
all: fmt-check validate lint test security docs ## Run all checks (CI mode)
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════$(RESET)"
	@echo "$(GREEN)  ✓ All checks passed$(RESET)"
	@echo "$(GREEN)═══════════════════════════════════════$(RESET)"

.PHONY: ci
ci: all ## Alias for 'all' — CI optimized

.PHONY: dev-setup
dev-setup: ## Install development tools (including tfenv)
	@echo "$(GREEN)Installing development tools...$(RESET)"
	@echo ""
	@echo "$(CYAN)Checking tfenv...$(RESET)"
	@if ! command -v tfenv &> /dev/null; then \
		echo "  Installing tfenv..."; \
		git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv 2>/dev/null || true; \
		if [[ ! -L /usr/local/bin/tfenv ]]; then \
			sudo ln -sf ~/.tfenv/bin/* /usr/local/bin/; \
		fi; \
	else \
		echo "  ✓ tfenv $$(tfenv --version 2>/dev/null || echo 'installed')"; \
	fi
	@echo ""
	@echo "$(CYAN)Installing terraform via tfenv...$(RESET)"
	@tfenv install $(TF_VERSION) 2>/dev/null || true
	@tfenv use $(TF_VERSION)
	@echo "  ✓ terraform $$(terraform version -json | jq -r '.terraform_version')"
	@echo ""
	@echo "$(CYAN)Checking tflint...$(RESET)"
	@if ! command -v tflint &> /dev/null; then \
		echo "  Installing tflint..."; \
		curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
	else \
		echo "  ✓ tflint $$(tflint --version | head -1)"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking trivy...$(RESET)"
	@if ! command -v trivy &> /dev/null; then \
		echo "  Installing trivy..."; \
		curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin; \
	else \
		echo "  ✓ trivy $$(trivy --version | head -1)"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking terraform-docs...$(RESET)"
	@if ! command -v terraform-docs &> /dev/null; then \
		echo "  Installing terraform-docs..."; \
		curl -sSLo /tmp/terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-v0.19.0-linux-amd64.tar.gz; \
		tar -xzf /tmp/terraform-docs.tar.gz -C /tmp; \
		sudo mv /tmp/terraform-docs /usr/local/bin/; \
	else \
		echo "  ✓ terraform-docs $$(terraform-docs version)"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking pre-commit...$(RESET)"
	@if ! command -v pre-commit &> /dev/null; then \
		echo "  Installing pre-commit..."; \
		pip3 install pre-commit; \
	else \
		echo "  ✓ pre-commit $$(pre-commit --version)"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking git-chglog...$(RESET)"
	@if ! command -v git-chglog &> /dev/null; then \
		echo "  Installing git-chglog..."; \
		curl -sSL https://github.com/git-chglog/git-chglog/releases/download/v0.15.4/git-chglog_0.15.4_linux_amd64.tar.gz | tar xz -C /tmp; \
		sudo mv /tmp/git-chglog /usr/local/bin/; \
	else \
		echo "  ✓ git-chglog installed"; \
	fi
	@echo ""
	@echo "$(GREEN)✓ All tools installed$(RESET)"

.PHONY: tf-install
tf-install: ## Install/switch terraform version via tfenv (reads .terraform-version)
	@echo "$(GREEN)Installing terraform $(TF_VERSION) via tfenv...$(RESET)"
	@tfenv install $(TF_VERSION) 2>/dev/null || true
	@tfenv use $(TF_VERSION)
	@echo "$(GREEN)✓ terraform $$(terraform version -json | jq -r '.terraform_version')$(RESET)"

.PHONY: hooks
hooks: ## Install pre-commit hooks
	@echo "$(GREEN)Installing pre-commit hooks...$(RESET)"
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Hooks installed$(RESET)"

.PHONY: changelog
changelog: ## Regenerate CHANGELOG.md from git history
	@echo "$(GREEN)Generating changelog...$(RESET)"
	@git-chglog -o CHANGELOG.md
	@echo "$(GREEN)✓ Changelog updated$(RESET)"

.PHONY: version
version: ## Show current version from git tags
	@git tag --sort=-version:refname | head -1 || echo "v0.0.0 (no tags)"

.PHONY: release
release: ## Create and push a version tag (use BUMP=patch|minor|major)
	@BUMP=$${BUMP:-patch}; \
	CURRENT=$$(git tag --sort=-version:refname | head -1 | sed 's/^v//'); \
	if [[ -z "$$CURRENT" ]]; then CURRENT="0.0.0"; fi; \
	IFS='.' read -r major minor patch <<< "$$CURRENT"; \
	case "$$BUMP" in \
		major) major=$$((major + 1)); minor=0; patch=0 ;; \
		minor) minor=$$((minor + 1)); patch=0 ;; \
		patch) patch=$$((patch + 1)) ;; \
	esac; \
	NEW="$${major}.$${minor}.$${patch}"; \
	echo "$(GREEN)Releasing v$$NEW (was v$$CURRENT)$(RESET)"; \
	git tag -a "v$$NEW" -m "Release v$$NEW"; \
	echo "$(YELLOW)Tag created. Push with: git push origin v$$NEW$(RESET)"

# =============================================================================
# Example Targets
# =============================================================================

.PHONY: example-init
example-init: ## Initialize the complete example (honours TF_UPGRADE)
	@cd $(EXAMPLES_DIR)/complete && terraform init $(TF_INIT_FLAGS)

.PHONY: example-plan
example-plan: example-init ## Plan the complete example (honours TF_REFRESH)
	@cd $(EXAMPLES_DIR)/complete && terraform plan $(TF_CMD_FLAGS)

.PHONY: example-apply
example-apply: example-init ## Apply the complete example (honours TF_REFRESH)
	@cd $(EXAMPLES_DIR)/complete && terraform apply $(TF_CMD_FLAGS)
