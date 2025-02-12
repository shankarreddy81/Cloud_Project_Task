provider "aws" {
  region = "ap-northeast-2"
}

# Declare the region variable
variable "region" {
  default = "ap-northeast-2"
}

# Create an S3 bucket for Lambda
resource "aws_s3_bucket" "hello_world_bucket" {
  bucket = "hello-world-website-bucket-unique-id"
}

# Create Lambda execution role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role-uniquee-id"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Lambda execution policy to the role
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda function
resource "aws_lambda_function" "hello_world_lambda" {
  filename         = "lambda.zip"
  function_name    = "hello_world_lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  source_code_hash = filebase64sha256("lambda.zip")
}

# Create API Gateway REST API
resource "aws_api_gateway_rest_api" "hello_world_api" {
  name        = "hello-world-api"
  description = "API to return Hello World"
}

# Create a resource for the endpoint
resource "aws_api_gateway_resource" "hello_world" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  parent_id   = aws_api_gateway_rest_api.hello_world_api.root_resource_id
  path_part   = "hello"
}

# Create a method for the endpoint (GET)
resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.hello_world_api.id
  resource_id   = aws_api_gateway_resource.hello_world.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create integration between API Gateway and Lambda
resource "aws_api_gateway_integration" "hello_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.hello_world_api.id
  resource_id             = aws_api_gateway_resource.hello_world.id
  http_method             = aws_api_gateway_method.hello_get.http_method
    request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello_world_lambda.arn}/invocations"
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Create API Gateway Stage (for prod)
resource "aws_api_gateway_stage" "prod_stage" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name = "prod"
}

# Create API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  depends_on = [aws_api_gateway_integration.hello_lambda]
}

# Output the API Gateway URL
output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.hello_world_api.id}.execute-api.${var.region}.amazonaws.com/prod/hello"
}