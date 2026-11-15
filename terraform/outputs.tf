output "cloudfront_url" {
  description = "Public URL of the CloudFront distribution (always available, with or without a custom domain)."
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket that holds the website files."
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed to create cache invalidations after deployments."
  value       = aws_cloudfront_distribution.website.id
}

output "website_url" {
  description = "Live URL — custom domain if configured, otherwise the CloudFront URL."
  value       = var.domain_name != null ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}
