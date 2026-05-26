#!/usr/bin/env bash
# Setup pre-commit hooks for the repository
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up git hooks..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "pre-commit not found. Installing..."
    pip3 install pre-commit
fi

cd "$PROJECT_ROOT"

# Install pre-commit hooks
pre-commit install
pre-commit install --hook-type commit-msg

echo "✓ Git hooks installed successfully"
echo ""
echo "Hooks will run automatically on every commit."
echo "To run manually: pre-commit run --all-files"
