# tf-molecule-s3-event-pipeline-aws
# Composes: S3 Bucket + Public Access Block + Encryption + Versioning + Policy + Notification + Lifecycle (opt)
# Purpose: S3 data landing zone with event-driven triggers for ETL, media processing, or data pipelines

# --- Core: S3 Bucket ---
module "bucket" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-aws.git?ref=ad2f7ac361eb89f873afe25769246898eb1e34ba"
  context = module.this.context

  force_destroy = var.force_destroy
}

# --- Security: Public Access Block (always block — pipeline buckets are never public) ---
module "public_access_block" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-public-access-block-aws.git?ref=141d21b8e5af97d018183e11d5e590758aab5d90"
  context = module.this.context

  bucket_id               = module.bucket.bucket_id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [module.bucket]
}

# --- Security: Encryption ---
module "encryption" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-encryption-aws.git?ref=a3f83c3ef6208f44428345c7bcbd9a8a05bd401d"
  context = module.this.context

  bucket_id          = module.bucket.bucket_id
  sse_algorithm      = var.sse_algorithm
  kms_master_key_id  = var.kms_key_id
  bucket_key_enabled = var.bucket_key_enabled

  depends_on = [module.bucket]
}

# --- Data Lineage: Versioning (always — enables reprocessing of source data) ---
module "versioning" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-versioning-aws.git?ref=6e0bbf0e604f26d50ef1f0459451e8f725f83b22"
  context = module.this.context

  bucket_id         = module.bucket.bucket_id
  versioning_status = var.versioning_status

  depends_on = [module.bucket]
}

# --- Access Control: Bucket Policy ---
module "policy" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-policy-aws.git?ref=c534c331a0cfec621b79d40de92710a97290966d"
  context = module.this.context

  bucket_id = module.bucket.bucket_id
  policy    = var.bucket_policy

  depends_on = [module.bucket]
}

# --- Event Triggers: Notifications (always — this is the molecule's core purpose) ---
module "notification" {
  source  = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-notification-aws.git?ref=9eae1fa230a0e4d15c5c6a2065eb85d9e3473857"
  context = module.this.context

  bucket_id            = module.bucket.bucket_id
  lambda_notifications = var.lambda_notifications
  sns_notifications    = var.sns_notifications
  sqs_notifications    = var.sqs_notifications

  depends_on = [module.bucket]
}

# --- Data Management: Lifecycle (optional — archive/expire processed data) ---
module "lifecycle_configuration" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-lifecycle-configuration-aws.git?ref=715e6b5fbcb1e4d77056c28b422937c03cb166c1"
  count  = var.enable_lifecycle ? 1 : 0

  context         = module.this.context
  bucket_id       = module.bucket.bucket_id
  lifecycle_rules = var.lifecycle_rules

  depends_on = [module.bucket]
}
