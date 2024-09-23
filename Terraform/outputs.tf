output "api_endpoint" {
  value = aws_api_gateway_deployment.lambda_deployment.invoke_url
}
output "lambda_role_arn" {
  description = "IAM Role ARN for Lambda execution"
  value       = aws_iam_role.lambda_role.arn
}
