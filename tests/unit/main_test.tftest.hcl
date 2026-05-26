# Unit Tests for Example Module
#
# These tests use mock providers — no real AWS calls are made.
# Run with: terraform test
# Run verbose: terraform test -verbose
# Run specific: terraform test -run "test_name"

mock_provider "aws" {}

# ---------------------------------------------------------------------------
# Test: Module creates resources with valid inputs
# ---------------------------------------------------------------------------
# variables {
#   name        = "test-bucket"
#   environment = "dev"
#   namespace   = "unit"
#   enabled     = true
# }
