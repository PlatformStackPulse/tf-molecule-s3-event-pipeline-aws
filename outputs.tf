output "bucket_id" {
  description = "ID of the S3 pipeline bucket"
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 pipeline bucket"
  value       = module.bucket.bucket_arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = module.bucket.bucket_regional_domain_name
}

output "versioning_status" {
  description = "Current versioning status"
  value       = module.versioning.versioning_status
}

output "encryption_algorithm" {
  description = "Encryption algorithm in use"
  value       = module.encryption.sse_algorithm
}
