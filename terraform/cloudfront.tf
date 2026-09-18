resource "aws_cloudfront_origin_access_control" "skippymart_oac" {
  name                              = "${aws_s3_bucket.skippymart.bucket}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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

  depends_on = [aws_acm_certificate_validation.skippymart_cert_validation]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}