# tf-molecule-s3-event-pipeline-aws

[![CI](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/ci.yml/badge.svg)](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/ci.yml)
[![Release](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/auto-release.yml/badge.svg)](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/auto-release.yml)
[![CodeQL](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/codeql.yml/badge.svg)](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/codeql.yml)
[![Changelog](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/changelog.yml/badge.svg)](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/actions/workflows/changelog.yml)
[![Latest Release](https://img.shields.io/github/v/release/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws?sort=semver)](https://github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws/releases)
![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.6.0-blueviolet?logo=terraform)
![License](https://img.shields.io/github/license/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws)

---

## Purpose

An S3 event-driven pipeline molecule that creates a data landing zone with built-in event notifications. Objects landing in this bucket automatically trigger Lambda functions, SQS queues, or SNS topics for downstream processing. Designed for ETL pipelines, media processing workflows, and data ingestion with fan-out patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  tf-molecule-s3-event-pipeline-aws                                          │
│                                                                             │
│  ┌──────────────────┐                                                       │
│  │ tf-atom-s3-      │──────────────────────────────────────────┐            │
│  │ bucket-aws       │                                          │            │
│  │ (landing zone)   │                                          │            │
│  └────────┬─────────┘                                          │            │
│           │ bucket_id                                          │            │
│           ├─────────────────┬──────────────────┬───────────────┤            │
│           ▼                 ▼                  ▼               ▼            │
│  ┌────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │ public-access- │ │ encryption   │ │ versioning   │ │ policy       │    │
│  │ block          │ │ (KMS)        │ │ (Enabled)    │ │ (cross-acct/ │    │
│  │ (all blocked)  │ │              │ │              │ │  service)    │    │
│  └────────────────┘ └──────────────┘ └──────────────┘ └──────────────┘    │
│           │                                                                 │
│           ├─────────────────────────────────────────┐                       │
│           ▼                                         ▼                       │
│  ┌────────────────────────────────────┐   ┌──────────────────┐             │
│  │ notification (CORE)                │   │ lifecycle        │             │
│  │ ┌───────┐ ┌───────┐ ┌───────┐    │   │ (optional)       │             │
│  │ │Lambda │ │  SQS  │ │  SNS  │    │   │                  │             │
│  │ └───┬───┘ └───┬───┘ └───┬───┘    │   └──────────────────┘             │
│  │     │         │         │         │                                      │
│  └─────┼─────────┼─────────┼────────┘                                      │
│         ▼         ▼         ▼                                               │
│    [Processing] [Queue] [Fan-out]                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Scope

| In Scope | Out of Scope |
|----------|--------------|
| Bucket creation with tf-label naming | Website hosting (→ `tf-molecule-s3-static-site-aws`) |
| Public access block (all 4 controls) | CORS configuration (→ `tf-molecule-s3-static-site-aws`) |
| Server-side encryption (KMS default) | Access logging (→ `tf-molecule-s3-secure-bucket-aws`) |
| Object versioning for data lineage | CloudFront distribution (→ `tf-molecule-s3-web-hosting-aws`) |
| Bucket policy (service principal/cross-account) | Lambda function creation |
| Event notifications (Lambda/SQS/SNS) | SQS queue creation |
| Lifecycle rules (optional archive/expire) | SNS topic creation |
| | Replication / Object lock |

## Features

- **Event-driven by design** — notifications are the molecule's core purpose, always configured
- **Multi-target support** — Lambda, SQS, and SNS notification targets simultaneously
- **Filter-based routing** — prefix and suffix filters for targeted event delivery
- **Data lineage** — versioning enabled by default for reprocessing source data
- **KMS encryption** — aws:kms default with Bucket Key for cost efficiency
- **Composed from atoms** — each concern is a separate, tested module
- **Optional lifecycle** — archive or expire processed data (e.g., Glacier after 30d)
- **Context propagation** — inherits namespace, environment, stage, name via tf-label

## Usage

### Minimal (Lambda trigger on object creation)

```hcl
module "pipeline_bucket" {
  source = "github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws?ref=v1.0.0"

  namespace   = "myorg"
  environment = "production"
  name        = "data-ingest"

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowServiceWrite"
      Effect    = "Allow"
      Principal = { Service = "logs.amazonaws.com" }
      Action    = ["s3:PutObject"]
      Resource  = "arn:aws:s3:::myorg-production-data-ingest/*"
    }]
  })

  lambda_notifications = [{
    lambda_function_arn = aws_lambda_function.etl_processor.arn
    events             = ["s3:ObjectCreated:*"]
  }]
}
```

### Full configuration (multi-target fan-out with lifecycle)

```hcl
module "pipeline_bucket" {
  source = "github.com/PlatformStackPulse/tf-molecule-s3-event-pipeline-aws?ref=v1.0.0"

  namespace   = "myorg"
  environment = "production"
  name        = "media-ingest"

  # KMS encryption with custom key
  kms_key_id = aws_kms_key.pipeline.arn

  # Cross-account write access
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "CrossAccountWrite"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:root" }
      Action    = ["s3:PutObject", "s3:PutObjectAcl"]
      Resource  = "arn:aws:s3:::myorg-production-media-ingest/*"
    }]
  })

  # Lambda for image processing
  lambda_notifications = [{
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events             = ["s3:ObjectCreated:*"]
    filter_suffix      = ".jpg"
  }]

  # SQS for video transcoding queue
  sqs_notifications = [{
    queue_arn     = aws_sqs_queue.video_queue.arn
    events       = ["s3:ObjectCreated:*"]
    filter_suffix = ".mp4"
  }]

  # SNS for audit/monitoring fan-out
  sns_notifications = [{
    topic_arn = aws_sns_topic.audit.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }]

  # Archive processed data
  enable_lifecycle = true
  lifecycle_rules = [
    {
      id              = "archive-processed"
      prefix          = "processed/"
      transition      = [{ days = 30, storage_class = "GLACIER" }]
      expiration_days = 365
    },
    {
      id              = "expire-temp"
      prefix          = "tmp/"
      expiration_days = 7
    }
  ]
}
```

## Composed Atoms

| Atom | Role in Molecule | Default |
|------|-----------------|---------|
| [`tf-atom-s3-bucket-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-aws) | Core data landing zone | Always created |
| [`tf-atom-s3-bucket-public-access-block-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-public-access-block-aws) | Block all public access | All 4 controls = true |
| [`tf-atom-s3-bucket-encryption-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-encryption-aws) | Encryption at rest | aws:kms with Bucket Key |
| [`tf-atom-s3-bucket-versioning-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-versioning-aws) | Object versioning for data lineage | Enabled |
| [`tf-atom-s3-bucket-policy-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-policy-aws) | Access control policy | User-provided (service/cross-account) |
| [`tf-atom-s3-bucket-notification-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-notification-aws) | Event triggers (CORE) | Lambda/SQS/SNS targets |
| [`tf-atom-s3-bucket-lifecycle-configuration-aws`](https://github.com/PlatformStackPulse/tf-atom-s3-bucket-lifecycle-configuration-aws) | Data retention/archival | Disabled (set rules to enable) |

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR to main, feature branches | Format, validate, lint, test, security |
| `auto-release.yml` | CI passes on main | Semantic version tag + GitHub Release + artifacts |
| `preview-release.yml` | CI passes on feature branch | Pre-release tag for testing |
| `codeql.yml` | Weekly + push main | SAST security analysis |
| `changelog.yml` | Push main | Auto-update CHANGELOG.md |
| `dependencies.yml` | Weekly | Check for provider updates |

## Module Documentation

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

### Providers

No providers.

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-aws.git | ad2f7ac361eb89f873afe25769246898eb1e34ba |
| <a name="module_encryption"></a> [encryption](#module\_encryption) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-encryption-aws.git | a3f83c3ef6208f44428345c7bcbd9a8a05bd401d |
| <a name="module_lifecycle_configuration"></a> [lifecycle\_configuration](#module\_lifecycle\_configuration) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-lifecycle-configuration-aws.git | 715e6b5fbcb1e4d77056c28b422937c03cb166c1 |
| <a name="module_notification"></a> [notification](#module\_notification) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-notification-aws.git | 9eae1fa230a0e4d15c5c6a2065eb85d9e3473857 |
| <a name="module_policy"></a> [policy](#module\_policy) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-policy-aws.git | c534c331a0cfec621b79d40de92710a97290966d |
| <a name="module_public_access_block"></a> [public\_access\_block](#module\_public\_access\_block) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-public-access-block-aws.git | 141d21b8e5af97d018183e11d5e590758aab5d90 |
| <a name="module_this"></a> [this](#module\_this) | git::https://github.com/PlatformStackPulse/tf-label.git | v1.0.0 |
| <a name="module_versioning"></a> [versioning](#module\_versioning) | git::https://github.com/PlatformStackPulse/tf-atom-s3-bucket-versioning-aws.git | 6e0bbf0e604f26d50ef1f0459451e8f725f83b22 |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | JSON-encoded IAM policy document for bucket access (e.g. cross-account write, service principal access) | `string` | n/a | yes |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_bucket_key_enabled"></a> [bucket\_key\_enabled](#input\_bucket\_key\_enabled) | Enable S3 Bucket Key to reduce KMS costs | `bool` | `true` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes and tags, which are merged. | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    namespace           = optional(string, null)<br/>    tenant              = optional(string, null)<br/>    environment         = optional(string, null)<br/>    stage               = optional(string, null)<br/>    name                = optional(string, null)<br/>    delimiter           = optional(string, null)<br/>    attributes          = optional(list(string), [])<br/>    tags                = optional(map(string), {})<br/>    label_order         = optional(list(string), null)<br/>    regex_replace_chars = optional(string, null)<br/>    id_length_limit     = optional(number, null)<br/>    label_key_case      = optional(string, null)<br/>    label_value_case    = optional(string, null)<br/>    labels_as_tags      = optional(set(string), null)<br/>    descriptor_formats = optional(map(object({<br/>      format = string<br/>      labels = list(string)<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | <pre>map(object({<br/>    format = string<br/>    labels = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_lifecycle"></a> [enable\_lifecycle](#input\_enable\_lifecycle) | Enable lifecycle rules for archiving/expiring processed data | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destruction of non-empty bucket (use only in dev/test) | `bool` | `false` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` to keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ARN for encryption (uses AWS-managed key if null) | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>Note: The value of the `name` tag, if included, will be the `id`, not the `name`. | `set(string)` | `null` | no |
| <a name="input_lambda_notifications"></a> [lambda\_notifications](#input\_lambda\_notifications) | Lambda function notification configurations for event-driven processing | <pre>list(object({<br/>    id                  = optional(string, null)<br/>    lambda_function_arn = string<br/>    events              = list(string)<br/>    filter_prefix       = optional(string, null)<br/>    filter_suffix       = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Lifecycle rules for processed data (e.g. move to Glacier after 30d, expire after 90d) | <pre>list(object({<br/>    id                                 = string<br/>    status                             = optional(string, "Enabled")<br/>    prefix                             = optional(string, "")<br/>    expiration_days                    = optional(number, null)<br/>    noncurrent_version_expiration_days = optional(number, null)<br/>    transition = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique. | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_sns_notifications"></a> [sns\_notifications](#input\_sns\_notifications) | SNS topic notification configurations for fan-out processing | <pre>list(object({<br/>    id            = optional(string, null)<br/>    topic_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string, null)<br/>    filter_suffix = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_sqs_notifications"></a> [sqs\_notifications](#input\_sqs\_notifications) | SQS queue notification configurations for decoupled processing | <pre>list(object({<br/>    id            = optional(string, null)<br/>    queue_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string, null)<br/>    filter_suffix = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm (AES256 or aws:kms). Defaults to KMS for pipeline data. | `string` | `"aws:kms"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element. A customer identifier, indicating who this instance of a resource is for. | `string` | `null` | no |
| <a name="input_versioning_status"></a> [versioning\_status](#input\_versioning\_status) | Versioning status (Enabled/Suspended). Enabled by default for data lineage. | `string` | `"Enabled"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 pipeline bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | ID of the S3 pipeline bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the bucket |
| <a name="output_encryption_algorithm"></a> [encryption\_algorithm](#output\_encryption\_algorithm) | Encryption algorithm in use |
| <a name="output_versioning_status"></a> [versioning\_status](#output\_versioning\_status) | Current versioning status |
<!-- END_TF_DOCS -->

## Contributing

1. Create a feature branch from `main`
2. Run `make fmt && make lint && make docs && make test`
3. Submit a PR — CI must pass before merge
4. Squash merge to `main` triggers auto-release
