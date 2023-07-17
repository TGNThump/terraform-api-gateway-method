data "aws_region" "default" {}

resource "aws_api_gateway_method" "default" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = var.http_method
  authorization = var.authorization
  authorizer_id = var.authorizer_id
}

resource "null_resource" "response_parameters" {
    triggers = {
        response_parameters = sha1(jsonencode(var.response_parameters))
    }
}

resource "aws_api_gateway_method_response" "default" {
  depends_on = [aws_api_gateway_method.default, null_resource.response_parameters]

  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "200"

  response_parameters = { for k,v in var.response_parameters : k => true }

  lifecycle {
    replace_triggered_by = [
      null_resource.response_parameters.triggers
    ]
    create_before_destroy = false
  }
}

data "aws_iam_policy_document" "apigw_access_step" {
  count = var.type == "STEP_EXPRESS" ? 1 : 0
  statement {
    actions = [
      "states:StartSyncExecution"
    ]
    resources = [
      var.step_function_arn
    ]
  }
}

resource "aws_iam_role" "step_express" {
  count = var.type == "STEP_EXPRESS" ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json
  name = "apigw_step_express_role"
  inline_policy {
    name = "apigw_step_express_policy"
    policy = data.aws_iam_policy_document.apigw_access_step[0].json
  }
}

resource "aws_api_gateway_integration" "step_express" {
  depends_on = [aws_api_gateway_method_response.default]
  count = var.type == "STEP_EXPRESS" ? 1 : 0

  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = var.http_method
  integration_http_method = "POST"
  type        = "AWS"
  credentials = aws_iam_role.step_express[0].arn
  uri         = "arn:aws:apigateway:${data.aws_region.default.id}:states:action/StartSyncExecution"
  passthrough_behavior = "NEVER"

  request_templates = {
    "application/json": jsonencode({
      input = replace(file("${path.module}/templates/step-express-request-input.json"), "\n", ""),
      stateMachineArn = var.step_function_arn
      name = "$context.requestId"
    })
  }
}

resource "aws_api_gateway_integration_response" "step_express" {
  count = var.type == "STEP_EXPRESS" ? 1 : 0
  depends_on = [aws_api_gateway_integration.step_express]

  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "200"

  response_parameters = var.response_parameters
  response_templates = {
    "application/json": templatefile("${path.module}/templates/step-express-response.json", {})
  }
}

resource "aws_api_gateway_integration" "default_mock" {
  count = var.type == "MOCK" ? 1 : 0
  depends_on = [aws_api_gateway_method_response.default]

  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = var.http_method
  type        = "MOCK"

  request_templates = {
    "application/json": jsonencode({
      "statusCode" : 200
    })
  }
}

resource "aws_api_gateway_integration_response" "default_mock" {
  count = var.type == "MOCK" ? 1 : 0
  depends_on = [aws_api_gateway_integration.default_mock, aws_api_gateway_method_response.default]

  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "200"

  response_parameters = var.response_parameters
  response_templates = {
    "application/json": var.mock_response_body
  }

  lifecycle {
    replace_triggered_by = [aws_api_gateway_method_response.default.response_parameters]
  }
}