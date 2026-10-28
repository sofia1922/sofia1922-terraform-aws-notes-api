
# 1. S3 bucket для зберігання нотаток

resource "aws_s3_bucket" "notes_bucket" {
  bucket = "devops-notes-api-bucket"
}

# Завантаження JSON-файлу в S3

resource "aws_s3_object" "notes_file" {
  bucket       = aws_s3_bucket.notes_bucket.id
  key          = "notes.json"
  source       = "${path.module}/notes.json"
  etag         = filemd5("${path.module}/notes.json")
  content_type = "application/json"
}

# 2. IAM роль для Lambda

resource "aws_iam_role" "lambda_role" {
  name = "notes-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Дозвіл Lambda читати файл із S3

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-read-notes"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.notes_bucket.arn}/*"
    }]
  })
}

# 3. Архівування Python-коду Lambda

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Створення Lambda-функції

resource "aws_lambda_function" "notes_lambda" {
  function_name = "notes-api-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 10

  environment {
    variables = {
      BUCKET_NAME     = aws_s3_bucket.notes_bucket.id
      S3_ENDPOINT_URL = "http://floci:4566"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_s3_policy,
    aws_s3_object.notes_file
  ]
}

# 4. API Gateway REST API

resource "aws_api_gateway_rest_api" "notes_api" {
  name        = "notes-api"
  description = "Simple Notes API using Lambda and S3"
}

# Створення маршруту /notes

resource "aws_api_gateway_resource" "notes_resource" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  parent_id   = aws_api_gateway_rest_api.notes_api.root_resource_id
  path_part   = "notes"
}

# HTTP метод GET

resource "aws_api_gateway_method" "get_notes" {
  rest_api_id   = aws_api_gateway_rest_api.notes_api.id
  resource_id   = aws_api_gateway_resource.notes_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Інтеграція API Gateway з Lambda

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  resource_id = aws_api_gateway_resource.notes_resource.id
  http_method = aws_api_gateway_method.get_notes.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.notes_lambda.invoke_arn
}

# Дозвіл API Gateway викликати Lambda

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notes_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.notes_api.execution_arn}/*/GET/notes"
}

# 5. Розгортання API

resource "aws_api_gateway_deployment" "notes_deployment" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.notes_resource.id,
      aws_api_gateway_method.get_notes.id,
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.notes_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.notes_api.id
  stage_name    = "dev"
}
