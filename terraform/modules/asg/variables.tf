variable "project_name" {
  description = "Project name for resource naming"
  type = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type = string
}

variable "secret_arns" {
  description = "ARNs of SSM Parameter secrets which ASG can access"
  type = list(string)
}

variable "kms_key_arns" {
  description = "ARNs of KMS keys to be used to decrypt SSM parameters"
  type = list(string)
}
