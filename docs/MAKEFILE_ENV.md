# Makefile & Environment Configuration

This template uses a Makefile with environment variable overrides for flexible local and CI workflows.

---

## Configuration Hierarchy

```
Environment variable (highest priority)
       │
       ▼
   .env file (local overrides, git-ignored)
       │
       ▼
  Makefile defaults (lowest priority)
```

Example:
```bash
# Makefile has:           TF_VERSION ?= 1.11.3
# .env has:              TF_VERSION=1.12.0
# Shell override:        TF_VERSION=1.13.0 make init
#
# Result: 1.13.0 wins (env var > .env > Makefile default)
```

---

## The `.env` File

Copy from the example and customise:

```bash
cp .env.example .env
```

### Available Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `TF_VERSION` | `1.11.3` | Terraform version (used by tfenv + Makefile) |
| `TFLINT_VERSION` | `v0.53.0` | TFLint version for linting |
| `TRIVY_VERSION` | `0.58.0` | Trivy version for security scanning |
| `TF_UPGRADE` | `false` | Add `-upgrade` to `terraform init` |
| `TF_REFRESH` | `true` | Control `-refresh` on plan/apply |
| `AWS_DEFAULT_REGION` | — | AWS region for examples/integration tests |
| `ARTIFACTORY_URL` | — | JFrog Artifactory URL (for publishing) |
| `ARTIFACTORY_REPO` | — | Artifactory repository name |

---

## Make Targets Reference

### Core Workflow

```bash
make init              # terraform init (uses TF_INIT_FLAGS)
make init-upgrade      # terraform init -upgrade (always)
make fmt               # terraform fmt -recursive
make fmt-check         # terraform fmt -check (CI mode)
make validate          # terraform validate
make lint              # tflint
make test              # Run unit tests
make test-unit         # Run unit tests (explicit)
make test-integration  # Run integration tests (needs AWS creds)
make security          # trivy IaC scan
make docs              # terraform-docs generation
make clean             # Remove .terraform dirs
make all               # Run everything (CI mode)
```

### Development

```bash
make dev-setup         # Install all tools (tfenv, tflint, trivy, etc.)
make tf-install        # Install/switch terraform version via tfenv
make hooks             # Install pre-commit hooks
```

### Versioning & Release

```bash
make version           # Show current version
make changelog         # Regenerate CHANGELOG.md
make release           # Create version tag (BUMP=patch|minor|major)
make release BUMP=minor  # Create minor version bump
```

### Examples

```bash
make example-init      # Init the complete example
make example-plan      # Plan (uses TF_CMD_FLAGS)
make example-apply     # Apply (uses TF_CMD_FLAGS)
```

---

## Flag Combinations Cheat Sheet

```bash
# Default: init normally, plan with refresh
make init && make example-plan

# Fast CI: no refresh, no upgrade
TF_REFRESH=false make example-plan

# Upgrade providers then plan
make init-upgrade && make example-plan

# Full upgrade + no-refresh (testing provider bump)
TF_UPGRADE=true TF_REFRESH=false make example-plan

# Set in .env for persistent config
echo "TF_REFRESH=false" >> .env
echo "TF_UPGRADE=true" >> .env
make example-plan    # picks up .env settings
```

---

## CI vs Local Settings

| Setting | Local Dev | CI |
|---------|-----------|-----|
| `TF_UPGRADE` | `false` (stable) | `false` (lock file pins) |
| `TF_REFRESH` | `true` (catch drift) | `false` (no cloud access in validate) |
| Backend | `-backend=false` | `-backend=false` (module testing) |
| Auto-approve | Never | Only after plan review |

---

## Adding New Variables

To add a new configurable flag:

1. **Add to Makefile** with conditional default:
   ```makefile
   MY_FLAG ?= default_value
   ```

2. **Add to `.env.example`** with documentation:
   ```bash
   # Description of what this does
   MY_FLAG=default_value
   ```

3. **Wire into computed flags** (if it affects terraform commands):
   ```makefile
   ifeq ($(MY_FLAG),true)
     TF_CMD_FLAGS += --my-flag
   endif
   ```

4. **Document in this file** in the settings table above.
