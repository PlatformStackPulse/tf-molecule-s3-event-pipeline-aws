# Template Guide

This guide explains how to use the Terraform Module Template to create a new module.

Each module lives in its own repository at the root level (no nested `modules/` directory). This follows the [Terraform Registry convention](https://developer.hashicorp.com/terraform/registry/modules/publish#requirements) and best practices for module reusability.

## Step 1: Create Repository

Repository **must** follow the naming convention `terraform-<PROVIDER>-<NAME>`:

```bash
# Create from template
gh repo create PlatformStackPulse/terraform-aws-vpc --template PlatformStackPulse/Terraform-module-base-template --public

# Clone locally
git clone git@github.com:PlatformStackPulse/terraform-aws-vpc.git
cd terraform-aws-vpc
```

## Step 2: Install Tools

```bash
make dev-setup    # Install terraform, tflint, trivy, terraform-docs, pre-commit, git-chglog
make hooks        # Install git pre-commit hooks
```

## Step 3: Define Your Resources

Edit `main.tf` at the repository root:

```hcl
# Replace the example S3 bucket with your resources
resource "aws_vpc" "this" {
  count = var.enabled ? 1 : 0

  cidr_block = var.cidr_block

  tags = local.tags
}
```

## Step 4: Define Variables

Edit `variables.tf`:

- Add `description` and `type` to every variable
- Use `validation {}` blocks for constraints
- Mark sensitive values with `sensitive = true`
- Group: required first, optional second, feature flags last

## Step 5: Define Outputs

Edit `outputs.tf`:

- Add `description` to every output
- Use `try()` for conditional resources: `value = try(resource.this[0].arn, null)`

## Step 6: Write Tests

Edit `tests/unit/main_test.tftest.hcl`:

```hcl
mock_provider "aws" {}

variables {
  name        = "test"
  environment = "dev"
  enabled     = true
}

run "creates_resource" {
  command = plan

  assert {
    condition     = length(aws_vpc.this) == 1
    error_message = "Expected VPC to be created."
  }
}
```

## Step 7: Write Examples

Edit `examples/complete/`:

- Show full usage with all optional features
- Reference the root module: `source = "../.."`
- Include a `terraform.tfvars.example` with realistic values
- Make it copy-paste ready for consumers

## Step 8: Validate

```bash
make all    # Run all checks: format, validate, lint, test, security, docs
```

## Step 9: Update Documentation

- Update `README.md` with your module's description and usage
- Update `.github/CODEOWNERS` with your team
- Update `.chglog/config.yml` with your repository URL
- Remove this guide or update it for your module

## Step 10: Publish

### Push and Release

```bash
git add -A
git commit -m "feat: initial module implementation"
git push origin main

# Create first release
make release BUMP=minor    # Creates v0.1.0
git push origin v0.1.0     # Triggers release workflow
```

### Connect to Terraform Registry

1. Go to [registry.terraform.io/github/create](https://registry.terraform.io/github/create)
2. Authorize with your GitHub account
3. Select the repository
4. Every new GitHub Release is auto-published to the registry

### Private Registry (Terraform Cloud/Enterprise)

1. In TFC/TFE → Registry → Publish Module
2. Select VCS provider and this repository
3. Tags auto-publish as new versions

## Directory Structure

```
terraform-aws-my-module/
├── main.tf               # Primary resource definitions
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Terraform and provider version constraints
├── locals.tf             # Computed values and naming
├── data.tf               # Data sources
├── README.md             # Module documentation (auto-generated sections)
├── examples/
│   └── complete/         # Full-featured usage example
│       ├── main.tf       # Calls your module with source = "../.."
│       ├── variables.tf  # Example inputs
│       ├── outputs.tf    # Example outputs
│       └── versions.tf   # Provider config
├── tests/
│   ├── unit/             # Unit tests (no AWS needed)
│   │   └── main_test.tftest.hcl
│   └── integration/      # Integration tests (real AWS)
│       └── main_test.tftest.hcl
├── .github/              # CI/CD workflows
└── Makefile              # Build automation
```

## Conventions

| Convention | Detail |
|-----------|--------|
| Repo Naming | `terraform-<PROVIDER>-<NAME>` (required for registry) |
| Commits | Conventional Commits: `feat:`, `fix:`, `docs:`, etc. |
| Versions | Semantic Versioning: `vMAJOR.MINOR.PATCH` |
| Variables | Always have `description`, `type`, and `validation` |
| Outputs | Always have `description` |
| Resources | Use `count = var.enabled ? 1 : 0` for disable support |
| Tags | Include `ManagedBy = "terraform"` and `Environment` |
| Naming | `{namespace}-{environment}-{name}` pattern |
| Testing | Native `terraform test` with `mock_provider` |
| Security | Trivy HIGH/CRITICAL, no hardcoded secrets |
| Docs | terraform-docs with `BEGIN_TF_DOCS`/`END_TF_DOCS` markers |
