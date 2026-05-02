# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------

output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.homework.id}.execute-api.us-east-1.amazonaws.com/${local.stage_name}"
}

output "js_endpoint" {
  value = "https://${aws_api_gateway_rest_api.homework.id}.execute-api.us-east-1.amazonaws.com/${local.stage_name}/js"
}

output "py_endpoint" {
  value = "https://${aws_api_gateway_rest_api.homework.id}.execute-api.us-east-1.amazonaws.com/${local.stage_name}/py"
}