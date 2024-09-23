variable "lambda_role_arn" {
  description = "IAM role for Lambda execution"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions"
  type        = number
  default     = 30
}
