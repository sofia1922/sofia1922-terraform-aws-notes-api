
output "api_url" {
  description = "Local Notes API endpoint"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.notes_api.id}/${aws_api_gateway_stage.dev.stage_name}/_user_request_/notes"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.notes_bucket.id
}

output "lambda_function_name" {
  value = aws_lambda_function.notes_lambda.function_name
}
