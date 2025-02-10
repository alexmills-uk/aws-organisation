variable "region" {
  default     = "eu-west-2"
  description = "AWS region"
}

variable "log_archive_days" {
  default     = 30
  description = "The number of days before Cloudtrail logs are moved to Glacier"
}

variable "log_expiry_days" {
  default     = 365
  description = "The number of days before Cloudtrail logs are deleted"
}