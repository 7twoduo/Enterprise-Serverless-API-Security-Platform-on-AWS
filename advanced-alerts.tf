# ------------------------------------------------------------
# API Gateway CloudWatch Logging Role
# ------------------------------------------------------------

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${local.project_name}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.api_gateway_cloudwatch_policy
  ]
}

# ------------------------------------------------------------
# API Gateway Access Logs
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/${local.project_name}-access-logs"
  retention_in_days = 14
}

# ------------------------------------------------------------
# API Gateway Usage Plan + API Key
# ------------------------------------------------------------

resource "aws_api_gateway_api_key" "client_key" {
  name        = "${local.project_name}-client-key"
  description = "API key for controlled access to ${local.project_name}"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "client_usage_plan" {
  name        = "${local.project_name}-usage-plan"
  description = "Usage plan with throttling and quota for API clients"

  api_stages {
    api_id = aws_api_gateway_rest_api.homework.id
    stage  = aws_api_gateway_stage.stage_production.stage_name
  }

  throttle_settings {
    rate_limit  = 25
    burst_limit = 50
  }

  quota_settings {
    limit  = 10000
    period = "MONTH"
  }

  depends_on = [
    aws_api_gateway_stage.stage_production
  ]
}

resource "aws_api_gateway_usage_plan_key" "client_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.client_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.client_usage_plan.id
}


#######################################################################################################
# ------------------------------------------------------------
# SNS Topic for CloudWatch Alarm Notifications
# ------------------------------------------------------------

resource "aws_sns_topic" "api_alerts" {
  name = "${local.project_name}-api-alerts"
}

resource "aws_sns_topic_subscription" "api_alerts_email" {
  topic_arn = aws_sns_topic.api_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ------------------------------------------------------------
# CloudWatch Alarms for Production-Style Monitoring
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${local.project_name}-api-5xx-errors"
  alarm_description   = "Triggers when API Gateway returns 5XX server errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Sum"

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"



  dimensions = {
    ApiName = aws_api_gateway_rest_api.homework.name
    Stage   = aws_api_gateway_stage.stage_production.stage_name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_high_latency" {
  alarm_name          = "${local.project_name}-api-high-latency"
  alarm_description   = "Triggers when API Gateway average latency is greater than 2 seconds."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 2000
  period              = 60
  statistic           = "Average"

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"



  dimensions = {
    ApiName = aws_api_gateway_rest_api.homework.name
    Stage   = aws_api_gateway_stage.stage_production.stage_name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "js_lambda_errors" {
  alarm_name          = "${local.project_name}-js-lambda-errors"
  alarm_description   = "Triggers when the JavaScript Lambda has errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Sum"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"




  dimensions = {
    FunctionName = aws_lambda_function.js_lambda.function_name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "py_lambda_errors" {
  alarm_name          = "${local.project_name}-py-lambda-errors"
  alarm_description   = "Triggers when the Python Lambda has errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Sum"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"




  dimensions = {
    FunctionName = aws_lambda_function.py_lambda.function_name
  }

  treat_missing_data = "notBreaching"
}



# ------------------------------------------------------------
# Advanced Alerting Lambda Package
# ------------------------------------------------------------

data "archive_file" "advanced_alerting_zip" {
  type        = "zip"
  output_path = "${path.module}/advanced-alerting.zip"

  source {
    filename = "index.py"
    content  = file("${path.module}/lambda-alerting/advanced-alerting.py")
  }
}


# ------------------------------------------------------------
# Advanced Alerting Lambda IAM
# ------------------------------------------------------------

resource "aws_iam_role" "advanced_alerting_role" {
  name = "${local.project_name}-advanced-alerting-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "advanced_alerting_basic_execution" {
  role       = aws_iam_role.advanced_alerting_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "advanced_alerting_sns_publish" {
  name        = "${local.project_name}-advanced-alerting-sns-publish"
  description = "Allow advanced alerting Lambda to publish formatted alarm messages to SNS."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.api_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "advanced_alerting_sns_publish" {
  role       = aws_iam_role.advanced_alerting_role.name
  policy_arn = aws_iam_policy.advanced_alerting_sns_publish.arn
}


# ------------------------------------------------------------
# Advanced Alerting Lambda
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "advanced_alerting_logs" {
  name              = "/aws/lambda/${local.project_name}-advanced-alerting"
  retention_in_days = 14
}

resource "aws_lambda_function" "advanced_alerting" {
  function_name    = "${local.project_name}-advanced-alerting"
  role             = aws_iam_role.advanced_alerting_role.arn
  runtime          = "python3.12"
  handler          = "index.lambda_handler"

  filename         = data.archive_file.advanced_alerting_zip.output_path
  source_code_hash = data.archive_file.advanced_alerting_zip.output_base64sha256

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.api_alerts.arn
      PROJECT_NAME  = local.project_name
    }
  }

  logging_config {
    log_group             = aws_cloudwatch_log_group.advanced_alerting_logs.name
    log_format            = "JSON"
    system_log_level      = "INFO"
    application_log_level = "INFO"
  }

  depends_on = [
    aws_cloudwatch_log_group.advanced_alerting_logs,
    aws_iam_role_policy_attachment.advanced_alerting_basic_execution,
    aws_iam_role_policy_attachment.advanced_alerting_sns_publish
  ]
}

# ------------------------------------------------------------
# EventBridge Rule for CloudWatch Alarm State Changes
# ------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "cloudwatch_alarm_state_change" {
  name        = "${local.project_name}-alarm-state-change"
  description = "Routes CloudWatch alarm state changes to the advanced alerting Lambda."

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "advanced_alerting_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_alarm_state_change.name
  target_id = "${local.project_name}-advanced-alerting"
  arn       = aws_lambda_function.advanced_alerting.arn
}

resource "aws_lambda_permission" "allow_eventbridge_advanced_alerting" {
  statement_id  = "AllowEventBridgeInvokeAdvancedAlerting"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.advanced_alerting.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_alarm_state_change.arn
}

