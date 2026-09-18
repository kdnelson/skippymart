resource "aws_route53_zone" "domain_zone" {
  name          = var.website_name
  force_destroy = false
}

resource "aws_route53_record" "skippymart_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.skippymart_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.domain_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_route53domains_registered_domain" "skippymart_domain" {
  domain_name = var.website_name

  name_server { name = aws_route53_zone.domain_zone.name_servers[0] }
  name_server { name = aws_route53_zone.domain_zone.name_servers[1] }
  name_server { name = aws_route53_zone.domain_zone.name_servers[2] }
  name_server { name = aws_route53_zone.domain_zone.name_servers[3] }
}

import {
  to = aws_route53domains_registered_domain.skippymart_domain
  id = var.website_name
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.domain_zone.zone_id
  name    = var.website_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.skippymart_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.skippymart_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.domain_zone.zone_id
  name    = "www.${var.website_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.skippymart_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.skippymart_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}