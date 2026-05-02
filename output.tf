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

output "api_key_value" {
  description = "THis is the secret value for the api key, find it in the statefule, it is how we can access the api."
  value     = aws_api_gateway_api_key.client_key.value
  sensitive = true
}
