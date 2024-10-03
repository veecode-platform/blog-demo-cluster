variable "aws_access_key" {
  description = "AWS Access Key ID."
  sensitive   = true
  default     = null
}

variable "aws_secret_key" {
  description = "AWS Access Secret Key."
  sensitive   = true
  default     = null
}

variable "aws_region" {
  description = "AWS Region."
  default     = null
}
