output "sha1" {
  value = sha1(jsonencode([
    aws_api_gateway_method.default,
    aws_api_gateway_method_response.default,
    aws_api_gateway_integration.default_mock,
    aws_api_gateway_integration.step_express,
    aws_api_gateway_integration_response.default_mock,
    aws_api_gateway_integration_response.step_express
  ]))
}