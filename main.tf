
# Terraform version and provider versions to run this code
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------
# IAM Role for both Lambda functions
# ------------------------------------------------------------
# Lambda Role for execution for both .py and .js
resource "aws_iam_role" "lambda_exec" {
  name = "${local.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
# This gives lambda the ability to write logs to cloudwatch log groups
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------
# The log group for the Javascript lambda function
resource "aws_cloudwatch_log_group" "js_lambda_logs" {
  name              = "/aws/lambda/${local.project_name}-js"
  retention_in_days = 14
}
# The log group for the Python lambda function
resource "aws_cloudwatch_log_group" "py_lambda_logs" {
  name              = "/aws/lambda/${local.project_name}-py"
  retention_in_days = 14
}

# The log group for the WAF-Web application Firewall
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${local.project_name}"
  retention_in_days = 14
}

# ------------------------------------------------------------
# Package Lambda Code
# ------------------------------------------------------------
# This packages up the .py and .js file into a format that can be uploaded to lambda and extracted to be used by lambda
data "archive_file" "py_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda-py.zip"

  source { # The directory path
    filename = "index.py"

    content = templatefile("${path.module}/lambda-py/index.py.tpl", {
      page_title       = "Python Function" # These are environment variables that make the lambda function essentially dynamic
      route_path       = "py"
      other_route_path = "js"
      other_page_title = "Java Function"
      language_name    = "Python"
    })
  }
}
# This packages up the .js and .js file into a format that can be uploaded to lambda and extracted to be used by lambda
data "archive_file" "js_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda-js.zip"

  source { # The directory path
    filename = "index.js"

    content = templatefile("${path.module}/lambda-js/index.js.tpl", {
      page_title       = "Java Function" # These are environment variables that make the lambda function essentially dynamic
      route_path       = "js"
      other_route_path = "py"
      other_page_title = "Python Function"
      language_name    = "JavaScript"
    })
  }
}

# ------------------------------------------------------------
# Lambda Functions
# ------------------------------------------------------------
# Javascript Function which runs the java side of this app
resource "aws_lambda_function" "js_lambda" {
  function_name    = "${local.project_name}-js"
  role             = aws_iam_role.lambda_exec.arn # The role it assumes
  runtime          = "nodejs20.x"
  handler          = "index.handler" # This is the handler that is called, if it is something else the handler has to be diffent
  filename         = data.archive_file.js_lambda_zip.output_path # encoded file
  source_code_hash = data.archive_file.js_lambda_zip.output_base64sha256 # format to extract said encoding

  timeout     = 30 # ttl
  memory_size = 128 # function size

  logging_config { # Sends Lambda logs to this CloudWatch log group and sets JSON log format with INFO-level logging
    log_group             = aws_cloudwatch_log_group.js_lambda_logs.name
    log_format            = "JSON"
    system_log_level      = "INFO"
    application_log_level = "INFO"
  }

  environment { # These are more environment variables that make the function more correct
  variables = {
    API_STAGE         = local.stage_name
    PAGE_TITLE        = "Java Function"
    ROUTE_PATH        = "js"
    OTHER_ROUTE_PATH  = "py"
    OTHER_PAGE_TITLE  = "Python Function"
    LANGUAGE_NAME     = "JavaScript"
    OTHER_LAMBDA_NAME = local.py_function_name
  }
  }

  depends_on = [
    aws_cloudwatch_log_group.js_lambda_logs
  ]
}
# Python Function

# Everything I said for nodejs, the exact same thing for python
resource "aws_lambda_function" "py_lambda" {
  function_name    = "${local.project_name}-py"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "index.lambda_handler"
  filename         = data.archive_file.py_lambda_zip.output_path
  source_code_hash = data.archive_file.py_lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 128

  logging_config {
    log_group             = aws_cloudwatch_log_group.py_lambda_logs.name
    log_format            = "JSON"
    system_log_level      = "INFO"
    application_log_level = "INFO"
  }

  environment {
  variables = {
    API_STAGE         = local.stage_name
    PAGE_TITLE        = "Python Function"
    ROUTE_PATH        = "py"
    OTHER_ROUTE_PATH  = "js"
    OTHER_PAGE_TITLE  = "Java Function"
    LANGUAGE_NAME     = "Python"
    OTHER_LAMBDA_NAME = local.js_function_name
  }
  }

  depends_on = [
    aws_cloudwatch_log_group.py_lambda_logs
  ]
}

# ------------------------------------------------------------
# REST API Gateway
# ------------------------------------------------------------

# This creates the base api with no paths or routes or backend or anything, just a hollow api
# At this point, it has no custom paths, methods, integrations, or backend targets.
resource "aws_api_gateway_rest_api" "homework" {
  name        = local.project_name
  description = "REST API with /js and /py Lambda integrations"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# This create the /js path that I will later point it to the backend lambda function
resource "aws_api_gateway_resource" "js" {
  rest_api_id = aws_api_gateway_rest_api.homework.id
  parent_id   = aws_api_gateway_rest_api.homework.root_resource_id # This is the root api and is what the nodejs attaches to
  path_part   = "js"
}

# This sets the integration as to the method that can be used to access the path i set previously.
# ANY allows clients to call /js with GET, POST, PUT, PATCH, DELETE, etc.
# authorization = "NONE" means no IAM/Cognito/Lambda authorizer is required.
# api_key_required = true means callers must provide an x-api-key header.
resource "aws_api_gateway_method" "js_any" {
  rest_api_id      = aws_api_gateway_rest_api.homework.id
  resource_id      = aws_api_gateway_resource.js.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true # This is important because it means that you need a secret header/ key to talk and that is the authentication for accessing the function.
}

# This adds the lambda function to the api and integrates the path and http methods to reach the lambda function
# Connects the /js API Gateway method to the JavaScript Lambda function.
# AWS_PROXY means API Gateway forwards the full request event to Lambda
# and expects Lambda to return a proxy response with statusCode, headers, and body.
resource "aws_api_gateway_integration" "js_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.homework.id
  resource_id             = aws_api_gateway_resource.js.id
  http_method             = aws_api_gateway_method.js_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.js_lambda.invoke_arn
}

# This creates the /py path for the api
resource "aws_api_gateway_resource" "py" {
  rest_api_id = aws_api_gateway_rest_api.homework.id
  parent_id   = aws_api_gateway_rest_api.homework.root_resource_id # This is the root api and is what the py attaches to
  path_part   = "py"
}
# This creates the methods that can talk with the path for the api which for this instance is all of them
resource "aws_api_gateway_method" "py_any" {
  rest_api_id      = aws_api_gateway_rest_api.homework.id
  resource_id      = aws_api_gateway_resource.py.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true # This is important because it means that you need a secret header/ key to talk and that is the authentication for accessing the function.
}
# This adds adds the lambda function python, it integrates the path and all the http methods that can call the function
resource "aws_api_gateway_integration" "py_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.homework.id
  resource_id             = aws_api_gateway_resource.py.id
  http_method             = aws_api_gateway_method.py_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # This proxies the requests to the lambda
  uri                     = aws_lambda_function.py_lambda.invoke_arn
}

# ------------------------------------------------------------
# Lambda Permissions for API Gateway
# ------------------------------------------------------------
# This gives the API the permission to invoke the lambda Python function from the lambda function and not from the api
resource "aws_lambda_permission" "allow_api_gateway_js" {
  statement_id  = "AllowExecutionFromApiGatewayJS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.js_lambda.function_name # It is all added to the specified lambda permissions
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.homework.execution_arn}/*/*/js"
}
# This gives the API the permission to invoke the lambda Python function from the lambda function and not from the api
resource "aws_lambda_permission" "allow_api_gateway_py" {
  statement_id  = "AllowExecutionFromApiGatewayPY"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.py_lambda.function_name # It is all added to the specified lambda permissions
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.homework.execution_arn}/*/*/py" 
}

# ------------------------------------------------------------
# API Deployment and Stage
# ------------------------------------------------------------

# Creates a deployment snapshot of the API Gateway configuration.
# API Gateway REST API changes do not become live until deployed to a stage.
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.homework.id

  triggers = { # This are the triggers of the redeployment of an image of the api bacause terraform does not always know the right time for redeploment
    redeployment = sha1(jsonencode([ 
      aws_api_gateway_resource.js.id,
      aws_api_gateway_method.js_any.id,
      aws_api_gateway_integration.js_lambda.id,
      aws_api_gateway_resource.py.id,
      aws_api_gateway_method.py_any.id,
      aws_api_gateway_integration.py_lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true # This makes sure the new deployment is created before it deletes the old deployment. Helps with persistence
  }

  depends_on = [
    aws_api_gateway_integration.js_lambda,
    aws_api_gateway_integration.py_lambda
  ]
}
# This creates the deployment and makes the api live
# Remember this is what makes the api live, live I say
resource "aws_api_gateway_stage" "stage_production" {
  rest_api_id   = aws_api_gateway_rest_api.homework.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = local.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn

    format = jsonencode({ # This is to pull out certain metadata about users going to a website that my lambda function uses, I have done this with cloudfront policies to make edge functions work
      requestId        = "$context.requestId" # Everything I said 1 line up, is wrong, this is just piping this metadata to a cloudwatch log group, lol
      extendedRequestId = "$context.extendedRequestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      resourcePath     = "$context.resourcePath"
      routePath        = "$context.path"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      responseLatency  = "$context.responseLatency"
      userAgent        = "$context.identity.userAgent"
      apiKeyId         = "$context.identity.apiKeyId"
    })
  }

  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_cloudwatch_log_group.api_gateway_access_logs
  ]
}

# ------------------------------------------------------------
# API Gateway Stage Method Settings
# ------------------------------------------------------------

# This is one big function that is essentially a configuration file for the live API, it is what allows me to limit the amount of times a user can make request my api to 25 and 50 for burst request

resource "aws_api_gateway_method_settings" "prod_all_methods" {
  rest_api_id = aws_api_gateway_rest_api.homework.id
  stage_name  = aws_api_gateway_stage.stage_production.stage_name
  method_path = "*/*" # This apply these rules to everything in the api, all http methods and all resources

  settings {
    metrics_enabled        = true # Turns on cloudwatch for api methods
    logging_level          = "INFO" # Sets cloudwatch log level to INFO
    data_trace_enabled     = false # This is set this way for production environments so it does not log sensitive data like passwords, user ids, etc

    throttling_rate_limit  = 25 # This allows the average request to be 25 per second
    throttling_burst_limit = 50 # This caps the number of request to be 50 per second for short spikes
  }

  depends_on = [
    aws_api_gateway_account.api_gateway_account
  ]
}
# ------------------------------------------------------------
# WAF Web ACL with Extracted Managed Rule Set
# ------------------------------------------------------------

resource "aws_wafv2_web_acl" "waf_rest_api" {
  name  = "${local.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }
# This is a set of predefined rules I wrote in variables file, i enabled cloudwatch so the logs get piped over there and this is part of my application protection posture
  dynamic "rule" {
    for_each = local.waf_managed_rules

    content {
      name     = rule.value.metric_name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }
# The rule is rate limiting and the clouwatch logs are enabled to pipe the logs out to cloudwatch
  rule {
    name     = "rate-limit"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true # This enables the logs to be pushed to cloudwatch
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true # This enables the logs to be pushed to cloudwatch
    metric_name                = "${local.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

# Attach WAF to REST API Gateway stage
resource "aws_wafv2_web_acl_association" "api_assoc" {
  resource_arn = aws_api_gateway_stage.stage_production.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_rest_api.arn

  depends_on = [
    aws_api_gateway_stage.stage_production
  ]
}

# WAF CloudWatch Logs
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  resource_arn = aws_wafv2_web_acl.waf_rest_api.arn

  # CloudWatch log group ARN can include :* depending on provider/API behavior,
  # so trimsuffix keeps the ARN valid for WAF logging.
  log_destination_configs = [
    trimsuffix(aws_cloudwatch_log_group.waf_logs.arn, ":*")
  ]

  depends_on = [
    aws_cloudwatch_log_group.waf_logs
  ]
}
