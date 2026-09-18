resource "aws_s3_bucket" "skippymart" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "skippymart" {
  bucket = aws_s3_bucket.skippymart.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "skippymart_policy" {
  bucket = aws_s3_bucket.skippymart.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.skippymart.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.skippymart_distribution.arn
          }
        }
      }
    ]
  })
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

resource "aws_route53domains_registered_domain" "skippymart_domain" {
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
  to = aws_route53domains_registered_domain.skippymart_domain
  id = var.website_name
}

resource "aws_cloudfront_origin_access_control" "skippymart_oac" {
  name = "${aws_s3_bucket.skippymart.bucket}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "skippymart_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["skippymart.com", "www.skippymart.com"]

  origin {
    domain_name              = aws_s3_bucket.skippymart.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.skippymart.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.skippymart_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.skippymart.bucket}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.skippymart_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [ aws_acm_certificate_validation.skippymart_cert_validation ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
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