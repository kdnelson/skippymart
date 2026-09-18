variable "bucket_name" {
  type = string
  description = "TF dynamically links the bucket name based on the Action workflow secret."
}

variable "website_name" {
  type = string
  default = "skippymart.com"
}