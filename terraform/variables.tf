variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region for the primary deployment (S3, CloudFront, Route 53)."
}

variable "domain_name" {
  type        = string
  nullable    = true
  default     = null
  description = "Custom domain name (e.g. vijaymore.com). Leave null to use the auto-generated CloudFront URL. When set, an ACM certificate is provisioned in us-east-1 and Route 53 records are created automatically."
}

variable "project_name" {
  type        = string
  default     = "vijay-website"
  description = "Short identifier used as a prefix for resource names."
}
