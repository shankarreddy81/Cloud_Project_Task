# Cloud_application_Project

This Terraform script sets up these resources:

- An S3 bucket
- A Lambda function with an execution role
- An API Gateway REST API with a resource, method, and integration to the Lambda function
- A Cognito User Pool, Client, and Identity Pool for Single Sign-On (SSO)

The resources are interconnected as follows:

- The Lambda function is triggered by the API Gateway integration
- The API Gateway REST API is secured by the Cognito User Pool and Client
- The Cognito Identity Pool is used to authenticate users for the API Gateway

Steps to Run the Code:

1. Install Terraform and AWS CLI on your machine
2. Create a new directory for your Terraform project and navigate into it
3. Copy the main.tf and sso.tf files into the directory
4. Create a new file named lambda.zip containing your Lambda function code (e.g., the index.jsfile)
5. Initialize the Terraform working directory by running terraform init
6. Apply the Terraform configuration by running terraform apply
7. Enter yes when prompted to confirm the deployment


Access URLs:

api_gateway_invoke_url = "https://zld557r48g.execute-api.ap-northeast-2.amazonaws.com/prod/hello"
api_gateway_sso_invoke_url = "https://zld557r48g.execute-api.ap-northeast-2.amazonaws.com/prod/sso-hello"

Architecture Overview (End-User Perspective):

1. End User: Accesses the API Gateway URL (e.g., https://api.execute-api.ap-northeast-2.amazonaws.com/prod/hello)
2. API Gateway: Receives the request and checks for authentication using the Cognito User Pool
    - If authenticated, proceeds to step 3
    - If not authenticated, returns an error response
3. Cognito User Pool: Verifies the user's identity and provides an authentication token
4. API Gateway: Uses the authentication token to authorize the request
5. API Gateway: Forwards the request to the Lambda function
6. Lambda Function: Processes the request and returns a response
7. API Gateway: Returns the response to the end user

SSO flow:

1. End User: Accesses the SSO-enabled API Gateway URL (e.g., https://api.execute-api.ap-northeast-2.amazonaws.com/prod/sso-hello)
2. API Gateway: Redirects the user to the Cognito Hosted UI for authentication
3. Cognito Hosted UI: Authenticates the user and provides an authorization code
4. API Gateway: Exchanges the authorization code for an access token
5. Cognito User Pool: Verifies the access token and provides an identity ID
6. API Gateway: Uses the identity ID to authorize the request
7. API Gateway: Forwards the request to the Lambda function
8. Lambda Function: Processes the request and returns a response
9. API Gateway: Returns the response to the end user
