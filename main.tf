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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "js_lambda_logs" {
  name              = "/aws/lambda/${local.project_name}-js"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "py_lambda_logs" {
  name              = "/aws/lambda/${local.project_name}-py"
  retention_in_days = 14
}

# WAF log group name must start with aws-waf-logs-
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${local.project_name}"
  retention_in_days = 14
}

# ------------------------------------------------------------
# Package Lambda Code
# ------------------------------------------------------------

data "archive_file" "py_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda-py.zip"

  source {
    filename = "index.py"

    content = templatefile("${path.module}/lambda-py/index.py.tpl", {
      page_title       = "Python Function"
      route_path       = "py"
      other_route_path = "js"
      other_page_title = "Java Function"
      language_name    = "Python"
    })
  }
}

data "archive_file" "js_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda-js.zip"

  source {
    filename = "index.js"

    content = templatefile("${path.module}/lambda-js/index.js.tpl", {
      page_title       = "Java Function"
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

resource "aws_lambda_function" "js_lambda" {
  function_name    = "${local.project_name}-js"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.js_lambda_zip.output_path
  source_code_hash = data.archive_file.js_lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 128

  logging_config {
    log_group             = aws_cloudwatch_log_group.js_lambda_logs.name
    log_format            = "JSON"
    system_log_level      = "INFO"
    application_log_level = "INFO"
  }

  environment {
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

resource "aws_api_gateway_rest_api" "homework" {
  name        = local.project_name
  description = "REST API with /js and /py Lambda integrations"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /js path
resource "aws_api_gateway_resource" "js" {
  rest_api_id = aws_api_gateway_rest_api.homework.id
  parent_id   = aws_api_gateway_rest_api.homework.root_resource_id
  path_part   = "js"
}

resource "aws_api_gateway_method" "js_any" {
  rest_api_id   = aws_api_gateway_rest_api.homework.id
  resource_id   = aws_api_gateway_resource.js.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "js_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.homework.id
  resource_id             = aws_api_gateway_resource.js.id
  http_method             = aws_api_gateway_method.js_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.js_lambda.invoke_arn
}

# /py path
resource "aws_api_gateway_resource" "py" {
  rest_api_id = aws_api_gateway_rest_api.homework.id
  parent_id   = aws_api_gateway_rest_api.homework.root_resource_id
  path_part   = "py"
}

resource "aws_api_gateway_method" "py_any" {
  rest_api_id   = aws_api_gateway_rest_api.homework.id
  resource_id   = aws_api_gateway_resource.py.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "py_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.homework.id
  resource_id             = aws_api_gateway_resource.py.id
  http_method             = aws_api_gateway_method.py_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.py_lambda.invoke_arn
}

# ------------------------------------------------------------
# Lambda Permissions for API Gateway
# ------------------------------------------------------------

resource "aws_lambda_permission" "allow_api_gateway_js" {
  statement_id  = "AllowExecutionFromApiGatewayJS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.js_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.homework.execution_arn}/*/*/js"
}

resource "aws_lambda_permission" "allow_api_gateway_py" {
  statement_id  = "AllowExecutionFromApiGatewayPY"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.py_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.homework.execution_arn}/*/*/py"
}

# ------------------------------------------------------------
# API Deployment and Stage
# ------------------------------------------------------------

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.homework.id

  triggers = {
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
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.js_lambda,
    aws_api_gateway_integration.py_lambda
  ]
}

resource "aws_api_gateway_stage" "stage_production" {
  rest_api_id   = aws_api_gateway_rest_api.homework.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = local.stage_name
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
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
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
