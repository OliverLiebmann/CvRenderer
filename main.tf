terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
  }
  backend "s3" {
    bucket = "grizzly-infrastructure"
    key    = "cv-renderer/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_iam_role" "cv_renderer_role" {
  name               = "cv-renderer-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
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


resource "aws_lambda_function" "cv_renderer" {
  filename      = "build/CvRenderer-${var.lambda-version}.jar"
  function_name = "cv-renderer"
  role          = aws_iam_role.cv_renderer_role.arn
  handler       = "CvRenderer::handleRequest"
  runtime       = "java21"
  timeout       = 300
  environment {}
}

resource "aws_cloudwatch_log_group" "cv_renderer_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.cv_renderer.function_name}"
  retention_in_days = 3
}

data "aws_iam_policy_document" "cv-renderer-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.cv_renderer_log_group.arn,
      "${aws_cloudwatch_log_group.cv_renderer_log_group.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "cv_renderer_role_policy" {
  policy = data.aws_iam_policy_document.cv-renderer-policy.json
  role   = aws_iam_role.cv_renderer_role.id
  name   = "cv-renderer-lambda-policy"
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "cv_renderer_api" {
  name        = "CvRendererAPI"
  description = "API for CV Renderer Lambda Function"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "cv_renderer_resource" {
  rest_api_id = aws_api_gateway_rest_api.cv_renderer_api.id
  parent_id   = aws_api_gateway_rest_api.cv_renderer_api.root_resource_id
  path_part   = "cv-renderer"
}

# API Gateway Method
resource "aws_api_gateway_method" "cv_renderer_method" {
  rest_api_id   = aws_api_gateway_rest_api.cv_renderer_api.id
  resource_id   = aws_api_gateway_resource.cv_renderer_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cv_renderer.function_name
  principal     = "apigateway.amazonaws.com"

  # This source_arn restricts the permission to a specific method ARN
  source_arn = "${aws_api_gateway_rest_api.cv_renderer_api.execution_arn}/*/POST/cv-renderer"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cv_renderer_api.id
  resource_id = aws_api_gateway_resource.cv_renderer_resource.id
  http_method = aws_api_gateway_method.cv_renderer_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cv_renderer.invoke_arn
}

resource "aws_api_gateway_deployment" "cv_renderer_deployment" {
  depends_on = [
    # This ensures that the deployment only occurs after any changes to the API
    aws_api_gateway_method.cv_renderer_method,
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.cv_renderer_api.id
  stage_name  = "prod" # Deploying directly to the 'prod' stage

  # Optional: Set description and deployment triggers
  description = "Deployment for the Production environment of Cv Renderer API"

  # You can use a lifecycle block to ensure that a new deployment is created on changes
  lifecycle {
    create_before_destroy = true
  }
}

# Output API Endpoint
output "production_api_endpoint" {
  description = "The endpoint for the production stage of the Cv Renderer API"
  value       = aws_api_gateway_deployment.cv_renderer_deployment.invoke_url
}