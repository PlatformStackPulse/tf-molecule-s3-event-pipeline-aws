#!/usr/bin/env bash
# Validate all Terraform modules locally
# Runs: fmt-check, validate, lint, test, security scan
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

ERRORS=0

cd "$PROJECT_ROOT"

echo "═══════════════════════════════════════"
echo "  Terraform Module Validation"
echo "═══════════════════════════════════════"
echo ""

# 1. Format check
echo -e "${GREEN}[1/5] Format check...${RESET}"
if terraform fmt -check -recursive > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Formatting OK${RESET}"
else
    echo -e "  ${RED}✗ Formatting issues found. Run: terraform fmt -recursive${RESET}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Validate
echo -e "${GREEN}[2/5] Validation...${RESET}"
terraform init -backend=false -input=false > /dev/null 2>&1
if ! terraform validate > /dev/null 2>&1; then
    echo -e "  ${RED}✗ Module validation failed${RESET}"
    terraform validate
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ Module valid${RESET}"
fi
echo ""

# 3. Lint
echo -e "${GREEN}[3/5] Linting...${RESET}"
if command -v tflint &> /dev/null; then
    tflint --init > /dev/null 2>&1
    if ! tflint > /dev/null 2>&1; then
        echo -e "  ${RED}✗ Lint issues found${RESET}"
        tflint
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓ Lint OK${RESET}"
    fi
else
    echo -e "  ${YELLOW}⚠ tflint not installed, skipping${RESET}"
fi
echo ""

# 4. Tests
echo -e "${GREEN}[4/5] Testing...${RESET}"
if [[ -d "tests/unit" ]]; then
    terraform init -backend=false -input=false > /dev/null 2>&1
    if ! terraform test -filter=tests/unit/ > /dev/null 2>&1; then
        echo -e "  ${RED}✗ Tests failed${RESET}"
        terraform test -filter=tests/unit/ -verbose
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓ Tests passed${RESET}"
    fi
else
    echo -e "  ${YELLOW}⚠ No unit tests found${RESET}"
fi
echo ""

# 5. Security scan
echo -e "${GREEN}[5/5] Security scan...${RESET}"
if command -v trivy &> /dev/null; then
    if ! trivy config . --severity HIGH,CRITICAL --tf-exclude-downloaded-modules --exit-code 1 > /dev/null 2>&1; then
        echo -e "  ${RED}✗ Security issues found${RESET}"
        trivy config . --severity HIGH,CRITICAL --tf-exclude-downloaded-modules
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓ No security issues${RESET}"
    fi
else
    echo -e "  ${YELLOW}⚠ trivy not installed, skipping${RESET}"
fi
echo ""

# Summary
echo "═══════════════════════════════════════"
if [[ "$ERRORS" -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All validations passed${RESET}"
else
    echo -e "  ${RED}✗ ${ERRORS} check(s) failed${RESET}"
fi
echo "═══════════════════════════════════════"

exit "$ERRORS"
