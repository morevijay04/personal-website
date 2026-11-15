# ── ACM DNS validation records ────────────────────────────────────────────────
# ACM asks us to prove domain ownership by publishing CNAME records. We iterate
# over the domain_validation_options emitted by the certificate resource.
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != null ? {
    for dvo in aws_acm_certificate.website[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = aws_route53_zone.website[0].zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

# ── A record (IPv4) ───────────────────────────────────────────────────────────
resource "aws_route53_record" "website_a" {
  count   = var.domain_name != null ? 1 : 0
  zone_id = aws_route53_zone.website[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── www A record (IPv4) ───────────────────────────────────────────────────────
resource "aws_route53_record" "website_www_a" {
  count   = var.domain_name != null ? 1 : 0
  zone_id = aws_route53_zone.website[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── AAAA record (IPv6) ────────────────────────────────────────────────────────
resource "aws_route53_record" "website_aaaa" {
  count   = var.domain_name != null ? 1 : 0
  zone_id = aws_route53_zone.website[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── www AAAA record (IPv6) ────────────────────────────────────────────────────
resource "aws_route53_record" "website_www_aaaa" {
  count   = var.domain_name != null ? 1 : 0
  zone_id = aws_route53_zone.website[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
