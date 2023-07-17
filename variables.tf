variable "rest_api_id" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "http_method" {
  type    = string
  default = "GET"
}

variable "type" {
    type    = string
    default = "MOCK"

  validation {
    condition     = contains(["MOCK", "STEP_EXPRESS"], var.type)
    error_message = "type must be one of MOCK or STEP_EXPRESS"
  }
}

variable "mock_response_body" {
  type = string
  default = "{}"
}

variable "response_parameters" {
  type = map(string)
  default = {}
}

variable "step_function_arn" {
    type = string
    default = null
}

variable "authorizer_id" {
  type = string
  default = null
}

variable "authorization" {
  type = string
  default = "NONE"
}