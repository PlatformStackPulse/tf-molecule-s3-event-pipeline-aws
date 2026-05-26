# Workflow Guide

## Branch Strategy

```
main (protected)
  ├── feat/add-lifecycle-rules
  ├── fix/output-when-disabled
  └── chore/update-providers
```

- `main` — Production branch, protected
- Feature branches — Created from `main`, merged via PR

## Branch Protection

Apply branch protection with:

```bash
./scripts/apply-branch-protection.sh PlatformStackPulse/Terraform-module-base-template
```

### Rules Applied

| Rule | Setting |
|------|---------|
| Required status checks | Format, Validate, TFLint, Test, Security |
| Strict status checks | Yes (branch must be up to date) |
| Required reviews | 1 approving review |
| Dismiss stale reviews | Yes |
| Code owner reviews | Required |
| Linear history | Required (no merge commits) |
| Force push | Disabled |
| Branch deletion | Disabled |

## CI/CD Pipeline

### On Every Push / PR

```
┌─────────────┐    ┌──────────┐    ┌────────┐    ┌──────┐    ┌──────────┐
│ Format Check │───▶│ Validate │───▶│ TFLint │───▶│ Test │    │ Security │
└─────────────┘    └──────────┘    └────────┘    └──────┘    └──────────┘
                                       │                          │
                                       └────────┬────────────────┘
                                                 │
                                            (parallel)
```

- **Format Check** — `terraform fmt -check -recursive`
- **Validate** — `terraform init -backend=false` + `terraform validate`
- **TFLint** — Lint with AWS ruleset
- **Test** — `terraform test` with mock providers
- **Security** — Trivy IaC scan (HIGH/CRITICAL)
- **Commit Lint** — PR title matches conventional commits
- **Docs Check** — terraform-docs are up to date

### On Tag Push (v*.*.*)

```
┌──────────┐    ┌─────────┐    ┌─────────────────┐
│ Validate │───▶│ Release │───▶│ GitHub Release   │
└──────────┘    └─────────┘    │ + Archive + SHA  │
                               └─────────────────┘
```

### Weekly Automation

- **CodeQL** — SAST security analysis (Monday 06:00 UTC)
- **Dependencies** — Check for provider updates (Monday 08:00 UTC)

### On Push to Main

- **Changelog** — Auto-update CHANGELOG.md from commits

## Release Process

### Automated (Recommended)

```bash
# Bump version
make release BUMP=patch    # v1.0.0 → v1.0.1
make release BUMP=minor    # v1.0.0 → v1.1.0
make release BUMP=major    # v1.0.0 → v2.0.0

# Push tag to trigger release
git push origin v1.0.1
```

### Manual (GitHub UI)

1. Go to Actions → Version Bump
2. Select bump type (patch/minor/major)
3. Run workflow

### What Happens on Release

1. Pre-release validation runs (format, validate, test)
2. Module archive created (`.tar.gz`)
3. SHA256 checksums generated
4. GitHub Release created with:
   - Release notes (from conventional commits)
   - Module archive
   - Checksums
   - Usage instructions

## Consuming Released Modules

```hcl
# Pin to specific version (recommended)
module "example" {
  source = "github.com/PlatformStackPulse/terraform-aws-my-module?ref=v1.0.0"
}

# Pin to major version
module "example" {
  source = "github.com/PlatformStackPulse/terraform-aws-my-module?ref=v1"
}

# Latest (not recommended for production)
module "example" {
  source = "github.com/PlatformStackPulse/terraform-aws-my-module"
}
```
