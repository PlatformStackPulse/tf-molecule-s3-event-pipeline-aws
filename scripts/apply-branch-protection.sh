#!/usr/bin/env bash
# Apply branch protection rules to the GitHub repository
# Requires: gh CLI authenticated with admin access
set -euo pipefail

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
    if [[ -z "$REPO" ]]; then
        echo "Usage: $0 <owner/repo>"
        exit 1
    fi
fi

echo "Applying branch protection to ${REPO}..."

gh api -X PUT "repos/${REPO}/branches/main/protection" \
    --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Terraform Format",
      "Terraform Validate",
      "TFLint",
      "Terraform Test",
      "Security Scan"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo "✓ Branch protection applied to main"
