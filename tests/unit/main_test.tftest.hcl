# Unit Tests for tf-molecule-s3-event-pipeline-aws
#
# These tests use a mock AWS provider — no real AWS calls are made.
# They assert on plan-KNOWN values (tf-label id string, module counts,
# input pass-throughs) rather than computed arn/id values, which are
# unknown under a mock provider.
#
# Run with:      terraform test -test-directory=tests/unit
# Run verbose:   terraform test -test-directory=tests/unit -verbose

mock_provider "aws" {}

variables {
  # tf-label context (namespace-stage-name => "eg-test-thing")
  namespace = "eg"
  stage     = "test"
  name      = "thing"

  # Module's own required input: a valid JSON bucket policy.
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowServiceWrite"
      Effect    = "Allow"
      Principal = { Service = "logs.amazonaws.com" }
      Action    = ["s3:PutObject"]
      Resource  = "arn:aws:s3:::eg-test-thing/*"
    }]
  })

  # A valid-looking Lambda notification target (ARN input).
  lambda_notifications = [{
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:eg-test-thing-etl"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }]
}

# ---------------------------------------------------------------------------
# Test: module creates resources with valid inputs (default enabled = true)
# ---------------------------------------------------------------------------
run "creates_when_enabled" {
  command = plan

  # tf-label id is plan-known and deterministic from namespace/stage/name.
  assert {
    condition     = module.this.id == "eg-test-thing"
    error_message = "Expected tf-label id 'eg-test-thing', got '${module.this.id}'."
  }

  # Versioning status pass-through is plan-known (default "Enabled").
  assert {
    condition     = output.versioning_status == "Enabled"
    error_message = "Expected versioning_status output to be 'Enabled'."
  }

  # Encryption algorithm pass-through is plan-known (default "aws:kms").
  assert {
    condition     = output.encryption_algorithm == "aws:kms"
    error_message = "Expected encryption_algorithm output to be 'aws:kms'."
  }
}

# ---------------------------------------------------------------------------
# Test: optional lifecycle module is not created by default
# ---------------------------------------------------------------------------
run "lifecycle_disabled_by_default" {
  command = plan

  assert {
    condition     = length(module.lifecycle_configuration) == 0
    error_message = "Expected 0 lifecycle_configuration modules when enable_lifecycle is false."
  }
}

# ---------------------------------------------------------------------------
# Test: enabling lifecycle creates exactly one lifecycle module
# ---------------------------------------------------------------------------
run "lifecycle_enabled_creates_one" {
  command = plan

  variables {
    enable_lifecycle = true
    lifecycle_rules = [{
      id              = "archive-processed"
      prefix          = "processed/"
      expiration_days = 365
      transition      = [{ days = 30, storage_class = "GLACIER" }]
    }]
  }

  assert {
    condition     = length(module.lifecycle_configuration) == 1
    error_message = "Expected exactly 1 lifecycle_configuration module when enable_lifecycle is true."
  }
}

# ---------------------------------------------------------------------------
# Test: disabling the whole module creates nothing (tf-label enabled=false)
# ---------------------------------------------------------------------------
run "disabled_creates_nothing" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = module.this.enabled == false
    error_message = "Expected tf-label context enabled to be false when enabled=false."
  }
}
