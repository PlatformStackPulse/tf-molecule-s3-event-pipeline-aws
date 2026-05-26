# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in this module, please report it responsibly.

**Do NOT open a public issue.**

Instead, email: **security@PlatformStackPulse.com**

Include:
- Description of the vulnerability
- Steps to reproduce
- Impact assessment
- Suggested fix (if any)

We will respond within 48 hours and work with you to resolve the issue.

## Security Scanning

This project uses multiple layers of security scanning:

### Automated (CI/CD)

| Tool | Scope | Trigger |
|------|-------|---------|
| **Trivy** | IaC vulnerability scanning | Every commit + PR |
| **TFLint** | AWS best practices enforcement | Every commit + PR |
| **CodeQL** | SAST analysis | Weekly + push to main |

### Pre-Commit

- `terraform_trivy` — Scans for HIGH/CRITICAL findings before commit
- `detect-private-key` — Prevents accidental key commits

### Manual

```bash
# Run security scan
make security

# Run all checks including security
make all
```

## Suppressing Findings

If a Trivy finding is a false positive, add it to `.trivyignore` with justification:

```
# .trivyignore
AVD-AWS-0089  # S3 logging intentionally disabled — this is a logging bucket itself
```

For inline suppressions in Terraform files:

```hcl
resource "aws_s3_bucket" "logs" {
  # trivy:ignore:AVD-AWS-0089 This IS the logging bucket
  bucket = "my-logs-bucket"
}
```

## Best Practices Enforced

- No hardcoded secrets in code or tfvars
- KMS or AES256 encryption on all storage resources
- Public access blocked on S3 buckets
- IAM policies follow least privilege
- All resources tagged with `ManagedBy = "terraform"`
- Provider versions pinned to prevent supply chain attacks
- Lock files (`.terraform.lock.hcl`) committed for reproducibility

## Dependency Management

Provider updates are checked weekly via the `dependencies.yml` workflow. Updates are submitted as PRs for review before merging.
