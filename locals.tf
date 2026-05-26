locals {
  enabled = module.this.enabled

  # Use tf-label's generated ID for resource naming
  #bucket_name = module.this.id

  # Standard tags from tf-label, merged with any module-specific tags
  tags = module.this.tags
}
