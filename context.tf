#
# Copy this file into your Terraform module to automatically get
# tf-label's standard configuration inputs suitable for passing
# to tf-label modules.
#
# Modules should access the whole context as `module.this.context`
# to get the input variables with nulls for defaults,
# for example `context = module.this.context`,
# and access individual variables as `module.this.<var>`,
# with final values filled in.
#

module "this" {
  source = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"

  enabled             = var.enabled
  namespace           = var.namespace
  tenant              = var.tenant
  environment         = var.environment
  stage               = var.stage
  name                = var.name
  delimiter           = var.delimiter
  attributes          = var.attributes
  tags                = var.tags
  label_order         = var.label_order
  regex_replace_chars = var.regex_replace_chars
  id_length_limit     = var.id_length_limit
  label_key_case      = var.label_key_case
  label_value_case    = var.label_value_case
  descriptor_formats  = var.descriptor_formats
  labels_as_tags      = var.labels_as_tags

  context = var.context
}

# Copy the variables from tf-label/variables.tf into your module
# to expose the same interface for context chaining.
################################################################################
# Context Variable — Typed with optional() (Terraform 1.3+)
#
# This replaces the old `type = any` workaround. The context object is fully
# typed, making it safe to pass between modules without losing type information.
# All fields use `optional()` with sensible defaults, eliminating the need for
# sentinel values like ["unset"] or ["default"].
################################################################################

variable "context" {
  type = object({
    enabled             = optional(bool, true)
    namespace           = optional(string, null)
    tenant              = optional(string, null)
    environment         = optional(string, null)
    stage               = optional(string, null)
    name                = optional(string, null)
    delimiter           = optional(string, null)
    attributes          = optional(list(string), [])
    tags                = optional(map(string), {})
    label_order         = optional(list(string), null)
    regex_replace_chars = optional(string, null)
    id_length_limit     = optional(number, null)
    label_key_case      = optional(string, null)
    label_value_case    = optional(string, null)
    labels_as_tags      = optional(set(string), null)
    descriptor_formats = optional(map(object({
      format = string
      labels = list(string)
    })), {})
  })
  default     = {}
  description = <<-EOT
    Single object for setting entire context at once.
    See description of individual variables for details.
    Leave string and numeric variables as `null` to use default value.
    Individual variable settings (non-null) override settings in context object,
    except for attributes and tags, which are merged.
  EOT

  validation {
    condition     = var.context.label_key_case == null ? true : contains(["lower", "title", "upper"], var.context.label_key_case)
    error_message = "context.label_key_case must be one of: lower, title, upper."
  }

  validation {
    condition     = var.context.label_value_case == null ? true : contains(["lower", "title", "upper", "none"], var.context.label_value_case)
    error_message = "context.label_value_case must be one of: lower, title, upper, none."
  }

  validation {
    condition = var.context.label_order == null ? true : alltrue([
      for l in var.context.label_order : contains(["namespace", "tenant", "environment", "stage", "name", "attributes"], l)
    ])
    error_message = "context.label_order may only contain: namespace, tenant, environment, stage, name, attributes."
  }
}

variable "enabled" {
  type        = bool
  default     = null
  description = "Set to false to prevent the module from creating any resources."
}

variable "namespace" {
  type        = string
  default     = null
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique."
}

variable "tenant" {
  type        = string
  default     = null
  description = "ID element. A customer identifier, indicating who this instance of a resource is for."
}

variable "environment" {
  type        = string
  default     = null
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'."
}

variable "stage" {
  type        = string
  default     = null
  description = "ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'."
}

variable "name" {
  type        = string
  default     = null
  description = <<-EOT
    ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.
    This is the only ID element not also included as a `tag`.
    The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input.
  EOT
}

variable "delimiter" {
  type        = string
  default     = null
  description = <<-EOT
    Delimiter to be used between ID elements.
    Defaults to `-` (hyphen). Set to `""` to use no delimiter at all.
  EOT
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = <<-EOT
    ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,
    in the order they appear in the list. New attributes are appended to the
    end of the list. The elements of the list are joined by the `delimiter`
    and treated as a single ID element.
  EOT
}

variable "labels_as_tags" {
  type        = set(string)
  default     = null
  description = <<-EOT
    Set of labels (ID elements) to include as tags in the `tags` output.
    Default is to include all labels.
    Tags with empty values will not be included in the `tags` output.
    Set to `[]` to suppress all generated tags.
    Note: The value of the `name` tag, if included, will be the `id`, not the `name`.
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).
    Neither the tag keys nor the tag values will be modified by this module.
  EOT
}

variable "label_order" {
  type        = list(string)
  default     = null
  description = <<-EOT
    The order in which the labels (ID elements) appear in the `id`.
    Defaults to ["namespace", "environment", "stage", "name", "attributes"].
    You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present.
  EOT

  validation {
    condition = var.label_order == null ? true : alltrue([
      for l in var.label_order : contains(["namespace", "tenant", "environment", "stage", "name", "attributes"], l)
    ])
    error_message = "label_order may only contain: namespace, tenant, environment, stage, name, attributes."
  }
}

variable "regex_replace_chars" {
  type        = string
  default     = null
  description = <<-EOT
    Terraform regular expression (regex) string.
    Characters matching the regex will be removed from the ID elements.
    If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits.
  EOT
}

variable "id_length_limit" {
  type        = number
  default     = null
  description = <<-EOT
    Limit `id` to this many characters (minimum 6).
    Set to `0` for unlimited length.
    Set to `null` to keep the existing setting, which defaults to `0`.
    Does not affect `id_full`.
  EOT

  validation {
    condition     = var.id_length_limit == null ? true : var.id_length_limit >= 6 || var.id_length_limit == 0
    error_message = "The id_length_limit must be >= 6 if supplied (not null), or 0 for unlimited length."
  }
}

variable "label_key_case" {
  type        = string
  default     = null
  description = <<-EOT
    Controls the letter case of the `tags` keys (label names) for tags generated by this module.
    Does not affect keys of tags passed in via the `tags` input.
    Possible values: `lower`, `title`, `upper`.
    Default value: `title`.
  EOT

  validation {
    condition     = var.label_key_case == null ? true : contains(["lower", "title", "upper"], var.label_key_case)
    error_message = "Allowed values: lower, title, upper."
  }
}

variable "label_value_case" {
  type        = string
  default     = null
  description = <<-EOT
    Controls the letter case of ID elements (labels) as included in `id`,
    set as tag values, and output by this module individually.
    Does not affect values of tags passed in via the `tags` input.
    Possible values: `lower`, `title`, `upper` and `none` (no transformation).
    Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.
    Default value: `lower`.
  EOT

  validation {
    condition     = var.label_value_case == null ? true : contains(["lower", "title", "upper", "none"], var.label_value_case)
    error_message = "Allowed values: lower, title, upper, none."
  }
}

variable "descriptor_formats" {
  type = map(object({
    format = string
    labels = list(string)
  }))
  default     = {}
  description = <<-EOT
    Describe additional descriptors to be output in the `descriptors` output map.
    Map of maps. Keys are names of descriptors. Values are maps of the form
    `{
       format = string
       labels = list(string)
    }`
    `format` is a Terraform format string to be passed to the `format()` function.
    `labels` is a list of labels, in order, to pass to `format()` function.
    Label values will be normalized before being passed to `format()` so they will be
    identical to how they appear in `id`.
    Default is `{}` (`descriptors` output will be empty).
  EOT
}
