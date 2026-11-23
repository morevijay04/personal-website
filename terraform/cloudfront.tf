# ── Managed cache policy ───────────────────────────────────────────────────────
# AWS provides a "CachingOptimized" managed policy that is recommended for S3
# static site origins. We look it up by name instead of hardcoding the ID.
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# ── CloudFront distribution ────────────────────────────────────────────────────
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  # Custom domain aliases — only set when var.domain_name is provided.
  aliases = var.domain_name != null ? [var.domain_name, "www.${var.domain_name}"] : []

  # ── Origin: private S3 bucket via OAC ───────────────────────────
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # ── Default cache behaviour ──────────────────────────────────────
  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  # ── SPA / single-page routing ────────────────────────────────────
  # Private S3 buckets with OAC return 403 (not 404) for missing objects,
  # so we must handle both. Map both back to index.html.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # ── TLS / viewer certificate ─────────────────────────────────────
  viewer_certificate {
    # When a custom domain is provided, use the ACM certificate issued in
    # us-east-1. Otherwise fall back to the default CloudFront certificate
    # (*.cloudfront.net) which requires SNI.
    acm_certificate_arn            = var.domain_name != null ? aws_acm_certificate_validation.website[0].certificate_arn : null
    cloudfront_default_certificate = var.domain_name == null
    ssl_support_method             = var.domain_name != null ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != null ? "TLSv1.2_2021" : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = var.project_name
  }
}
