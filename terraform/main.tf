resource "aws_s3_bucket" "skippymart" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "skippymart" {
  bucket = aws_s3_bucket.skippymart.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_acm_certificate" "skippymart_cert" {
  domain_name       = "skippymart.com"
  validation_method = "DNS"
  subject_alternative_names = [ "www.skippymart.com" ]

  lifecycle {
    create_before_destroy = true
  }
}