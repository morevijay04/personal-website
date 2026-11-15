# ── Random suffix ─────────────────────────────────────────────────────────────
# Guarantees a globally-unique bucket name without manually choosing one.
resource "random_id" "suffix" {
  byte_length = 4
}

# ── S3 bucket ──────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-${random_id.suffix.hex}"

  tags = {
    Project = var.project_name
  }
}

# Block every form of public access — objects are served exclusively via
# CloudFront using Origin Access Control (OAC).
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning so you can roll back accidental deployments.
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── CloudFront Origin Access Control ──────────────────────────────────────────
# OAC is the modern replacement for OAI. It signs requests from CloudFront to
# S3 using SigV4, keeping the bucket completely private.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── Bucket policy ──────────────────────────────────────────────────────────────
# Grants only the CloudFront service principal GetObject access, scoped to the
# specific CloudFront distribution via the OAC condition.
data "aws_iam_policy_document" "website_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website_bucket_policy.json

  # The distribution must exist before we can reference its ARN.
  depends_on = [aws_cloudfront_distribution.website]
}
