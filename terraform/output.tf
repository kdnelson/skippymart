output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.skippymart_distribution.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.skippymart.id
}