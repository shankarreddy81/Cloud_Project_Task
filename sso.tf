# Cognito User Pool for SSO
resource "aws_cognito_user_pool" "sso_user_pool" {
  name                     = "sso-user-pool"
  username_attributes      = ["email"]
  email_verification_subject = "Your verification code"
  email_verification_message  = "Your verification code is {####}"
  sms_authentication_message  = "Your authentication code is {####}"
  mfa_configuration            = "OFF"
  password_policy {
    minimum_length = 8
    require_uppercase = true
    require_numbers = true
    require_symbols = true
  }
}

# Cognito User Pool Client for SSO
resource "aws_cognito_user_pool_client" "sso_client" {
  name                                 = "sso-client"
  user_pool_id                         = aws_cognito_user_pool.sso_user_pool.id
  generate_secret                       = true
  explicit_auth_flows                  = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                  = ["email", "openid", "profile"]
  callback_urls                          = ["https://example.com/callback"]
}

# Cognito Identity Pool for SSO
resource "aws_cognito_identity_pool" "sso_identity_pool" {
  identity_pool_name               = "sso-identity-pool"
  allow_unauthenticated_identities = false
}

# IAM Role for SSO Authenticated Users
resource "aws_cognito_identity_pool_roles_attachment" "sso_roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.sso_identity_pool.id
  roles = {
    authenticated = aws_iam_role.lambda_execution_role.arn
  }
}

# API Gateway Authorizer for SSO
resource "aws_api_gateway_authorizer" "sso_authorizer" {
  name          = "sso-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.hello_world_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.sso_user_pool.arn]
}

# API Gateway Resource and Method for SSO
resource "aws_api_gateway_resource" "sso_hello" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  parent_id   = aws_api_gateway_rest_api.hello_world_api.root_resource_id
  path_part   = "sso-hello"
}

# API Gateway Method for SSO
resource "aws_api_gateway_method" "sso_hello_get" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  resource_id = aws_api_gateway_resource.sso_hello.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.sso_authorizer.id
}

resource "aws_api_gateway_integration" "sso_hello_lambda" {
rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
resource_id = aws_api_gateway_resource.sso_hello.id
http_method = aws_api_gateway_method.sso_hello_get.http_method
integration_http_method = "POST"
type        = "AWS_PROXY"
uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello_world_lambda.arn}/invocations"
}

output "api_gateway_sso_invoke_url" {
value = "https://${aws_api_gateway_rest_api.hello_world_api.id}.execute-api.${var.region}.amazonaws.com/prod/sso-hello"
}