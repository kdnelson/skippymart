resource "aws_acm_certificate" "skippymart_cert" {
  provider                  = aws.us_east_1
  domain_name               = var.website_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.skippymart.com"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "skippymart_cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.skippymart_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.skippymart_cert_validation : record.fqdn]

  timeouts {
    create = "15m"
  }
}