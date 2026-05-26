# Integration Tests for Example Module
#
# These tests run against a real AWS provider.
# Requires valid AWS credentials.
#
# Run with: terraform test -filter=tests/integration/
#
# WARNING: These tests create real AWS resources.
# Costs may be incurred. Resources are cleaned up after tests.

# Uncomment and configure when ready for integration testing:
#
# provider "aws" {
#   region = "eu-west-1"
# }
#
# variables {
#   name        = "integration-test"
#   environment = "dev"
#   namespace   = "test"
#   enabled     = true
#   force_destroy = true  # Allow cleanup
# }
#
# run "creates_real_bucket" {
#   command = apply
#
#   assert {
#     condition     = aws_s3_bucket.this[0].id != ""
#     error_message = "S3 bucket should be created with a valid ID."
#   }
#
#   assert {
#     condition     = aws_s3_bucket.this[0].bucket == "test-dev-integration-test"
#     error_message = "Bucket name should follow naming convention."
#   }
# }
