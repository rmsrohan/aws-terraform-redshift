###############################################################################
# Variables - Environment
###############################################################################
variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "region" {
  description = "Default Region"
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Name of the environment for the deployment, e.g. Integration, PreProduction, Production, QA, Staging, Test"
  default     = "Development"
}

variable "app_name" {
  description = "Name of the application to deploy"
  default     = "Demo"
}

