output "role_arn" {
  description = "The ARN of the custodian role"
  value       = aws_iam_role.role.arn
}