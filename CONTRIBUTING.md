# Contributing

Thank you for contributing to this Terraform module!

## Development Setup

```bash
# Clone the repository
git clone git@github.com:PlatformStackPulse/Terraform-module-base-template.git
cd Terraform-module-base-template

# Install tools
make dev-setup

# Install git hooks
make hooks
```

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make your changes**
   - Edit module files in `modules/`
   - Update tests in `tests/`
   - Update examples in `examples/`

3. **Run all checks**
   ```bash
   make all
   ```

4. **Commit with conventional format**
   ```bash
   git commit -m "feat(module): add support for lifecycle rules"
   ```

5. **Push and create PR**
   ```bash
   git push origin feat/my-feature
   ```

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace |
| `refactor` | Code change (no new feature or fix) |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependencies |
| `build` | Build system changes |
| `ci` | CI/CD pipeline changes |
| `revert` | Revert a previous commit |

### Examples

```
feat(s3): add support for intelligent tiering
fix(outputs): correct bucket_arn output when disabled
docs: update usage examples in README
test: add validation tests for environment variable
chore(deps): update AWS provider to ~> 6.0
ci: add infracost estimation to PR
```

## Pre-Commit Hooks

Hooks run automatically on every commit:

- **terraform_fmt** — Formats HCL files
- **terraform_validate** — Validates syntax
- **terraform_tflint** — Lints against AWS best practices
- **terraform_docs** — Generates README documentation
- **terraform_trivy** — Scans for security issues
- **gitlint** — Validates commit message format

To run manually:

```bash
pre-commit run --all-files
```

## Testing

### Unit Tests (No AWS credentials needed)

```bash
make test-unit
```

Unit tests use `mock_provider` — they run entirely locally without API calls.

### Integration Tests (AWS credentials required)

```bash
make test-integration
```

Integration tests create real AWS resources. Ensure you have valid credentials and understand cost implications.

### Writing Tests

```hcl
# tests/unit/my_test.tftest.hcl

mock_provider "aws" {}

variables {
  name        = "test"
  environment = "dev"
}

run "my_test_case" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this[0].bucket == "dev-test"
    error_message = "Unexpected bucket name."
  }
}
```

## Code Quality

Before submitting a PR, ensure:

- [ ] `make fmt-check` passes
- [ ] `make validate` passes
- [ ] `make lint` passes
- [ ] `make test` passes
- [ ] `make security` passes
- [ ] `make docs` generates up-to-date documentation
- [ ] All variables have `description` and `type`
- [ ] All outputs have `description`
- [ ] Examples are updated

## Release Process

Releases are automated via GitHub Actions:

1. Merge PR to `main`
2. Run `make release BUMP=patch` (or `minor`/`major`)
3. Push the tag: `git push origin v1.2.3`
4. Release workflow creates GitHub Release with artifacts
