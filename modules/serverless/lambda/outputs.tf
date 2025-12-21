# =================================================================================
# Module: serverless/lambda/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.email_handler.arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.email_handler.function_name
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.email_handler.invoke_arn
}
