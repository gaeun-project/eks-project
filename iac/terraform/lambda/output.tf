output "lambda_arn" {
  description = "The ARN of the custodian role"
  value       = aws_lambda_function.lambda.arn
}