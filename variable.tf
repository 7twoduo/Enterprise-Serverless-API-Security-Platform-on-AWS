# Locals Files
locals {
  project_name = "homework-rest-api"
  stage_name   = "prod"

  py_function_name = "${local.project_name}-py"
  js_function_name = "${local.project_name}-js"

  waf_managed_rules = [
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      metric_name = "bad_inputs"
      priority    = 1
    },
    {
      name        = "AWSManagedRulesCommonRuleSet"
      metric_name = "common_rule_set"
      priority    = 2
    },
    {
      name        = "AWSManagedRulesSQLiRuleSet"
      metric_name = "sql_injection_rule_set"
      priority    = 3
    }
  ]
}



variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "my-basic-lambda-java"
}
variable "function_name1" {
  description = "Name of the Lambda function"
  type        = string
  default     = "my-basic-lambda-python"
}