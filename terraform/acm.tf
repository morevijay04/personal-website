# ── ACM certificate ───────────────────────────────────────────────────────────
# CloudFront only accepts ACM certificates from us-east-1, so we must use the
# aliased provider here even if the rest of the stack is in another region.
#
# count = 1 when domain_name is set, 0 otherwise (no-domain shortcut).

resource "aws_acm_certificate" "website" {
  count    = var.domain_name != null ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  # Allow Terraform to replace the cert if the domain changes without
  # first trying to destroy the old one (which CloudFront would block).
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = var.project_name
  }
}

# ── DNS validation waiter ─────────────────────────────────────────────────────
# This resource blocks until ACM confirms that all DNS validation records have
# been verified. It depends on the Route 53 records created in route53.tf.
resource "aws_acm_certificate_validation" "website" {
  count    = var.domain_name != null ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
