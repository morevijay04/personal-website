# ── Route 53 hosted zone ───────────────────────────────────────────────────────
# Created here (not looked up) because we're registering the domain via
# Terraform. The registration resource will point nameservers at this zone.
resource "aws_route53_zone" "website" {
  count = var.domain_name != null ? 1 : 0
  name  = var.domain_name

  tags = {
    Project = var.project_name
  }
}

# ── Domain registration ────────────────────────────────────────────────────────
# Manages the already-registered domain (nameservers, contacts, auto-renew).
# The initial registration must be done via CLI or the AWS console and then
# imported: terraform import 'aws_route53domains_registered_domain.website[0]' vijaymore.com
#
# Route 53 Domains API is only available in us-east-1.
resource "aws_route53domains_registered_domain" "website" {
  count    = var.domain_name != null ? 1 : 0
  provider = aws.us_east_1

  domain_name = var.domain_name
  auto_renew  = true

  dynamic "name_server" {
    for_each = tolist(aws_route53_zone.website[0].name_servers)
    content {
      name = name_server.value
    }
  }

  registrant_contact {
    first_name     = var.contact_first_name
    last_name      = var.contact_last_name
    contact_type   = "PERSON"
    email          = var.contact_email
    phone_number   = var.contact_phone
    address_line_1 = var.contact_address
    city           = var.contact_city
    country_code   = var.contact_country_code
    zip_code       = var.contact_zip_code
  }

  admin_contact {
    first_name     = var.contact_first_name
    last_name      = var.contact_last_name
    contact_type   = "PERSON"
    email          = var.contact_email
    phone_number   = var.contact_phone
    address_line_1 = var.contact_address
    city           = var.contact_city
    country_code   = var.contact_country_code
    zip_code       = var.contact_zip_code
  }

  tech_contact {
    first_name     = var.contact_first_name
    last_name      = var.contact_last_name
    contact_type   = "PERSON"
    email          = var.contact_email
    phone_number   = var.contact_phone
    address_line_1 = var.contact_address
    city           = var.contact_city
    country_code   = var.contact_country_code
    zip_code       = var.contact_zip_code
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = var.project_name
  }
}
