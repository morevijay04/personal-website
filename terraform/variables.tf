variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region for the primary deployment (S3, CloudFront, Route 53)."
}

variable "domain_name" {
  type        = string
  nullable    = true
  default     = "vijaymore.com"
  description = "Custom domain name. Set to null to use the auto-generated CloudFront URL instead."
}

variable "project_name" {
  type        = string
  default     = "vijay-website"
  description = "Short identifier used as a prefix for resource names."
}

# ── Domain registrant contact ──────────────────────────────────────────────────
# Required for domain registration. Set these in terraform.tfvars (gitignored).

variable "contact_first_name" {
  type    = string
  default = "Vijay"
}

variable "contact_last_name" {
  type    = string
  default = "More"
}

variable "contact_email" {
  type    = string
  default = "more.vijayb04@gmail.com"
}

variable "contact_phone" {
  type        = string
  description = "Phone in E.164 format: +CountryCode.Number (e.g. +65.91234567)"
}

variable "contact_address" {
  type        = string
  description = "Street address line 1."
}

variable "contact_city" {
  type    = string
  default = "Singapore"
}

variable "contact_country_code" {
  type    = string
  default = "SG"
}

variable "contact_zip_code" {
  type        = string
  description = "Postal / ZIP code."
}
