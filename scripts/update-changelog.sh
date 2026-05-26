#!/usr/bin/env bash
# Update CHANGELOG.md from git history using git-chglog
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

if ! command -v git-chglog &> /dev/null; then
    echo "git-chglog not found. Install with: make dev-setup"
    exit 1
fi

echo "Generating CHANGELOG.md..."
git-chglog -o CHANGELOG.md

echo "✓ CHANGELOG.md updated"
