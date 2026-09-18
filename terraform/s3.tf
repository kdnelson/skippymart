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

data "aws_iam_policy_document" "skippymart_cloudfront_access" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.skippymart.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.skippymart_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "skippymart_policy" {
  bucket = aws_s3_bucket.skippymart.id
  policy = data.aws_iam_policy_document.skippymart_cloudfront_access.json

  depends_on = [aws_cloudfront_distribution.skippymart_distribution]
}