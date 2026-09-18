resource "aws_s3_bucket" "skippymart" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "skippymart" {
  bucket = aws_s3_bucket.skippymart.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_route53_zone" "domain_zone" {
  name          = var.website_name
  force_destroy = false
}

resource "aws_acm_certificate" "skippymart_cert" {
  provider          = aws.us_east_1
  domain_name       = var.website_name
  validation_method = "DNS"
  subject_alternative_names = [ "www.skippymart.com" ]

  lifecycle {
    create_before_destroy = true
  }
}

# data "aws_route53_zone" "domain_zone" {
#   name         = "skippymart.com"
#   private_zone = false
# }

resource "aws_route53_record" "skippymart_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.skippymart_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.domain_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
  allow_overwrite = true
}

# This resource will wait for the cert to complete.
resource "aws_acm_certificate_validation" "skippymart_cert_validation" {
  provider = aws.us_east_1
  certificate_arn         = aws_acm_certificate.skippymart_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.skippymart_cert_validation : record.fqdn]

  timeouts {
    create = "15m"
  }
}

resource "aws_route53_domains_registered_domain" "skippymart_domain" {
  domain_name = var.website_name

  name_server {
    name = aws_route53_zone.domain_zone.name_servers[0]
  }
  name_server {
    name = aws_route53_zone.domain_zone.name_servers[1]
  }
  name_server {
    name = aws_route53_zone.domain_zone.name_servers[2]
  }
  name_server {
    name = aws_route53_zone.domain_zone.name_servers[3]
  }
}

import {
  to = aws_route53_domains_registered_domain.skippymart_domain
  id = var.website_name
}