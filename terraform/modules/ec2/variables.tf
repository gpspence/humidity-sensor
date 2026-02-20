variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "secret_arns" {
  description = "ARNs of SSM Parameter secrets which ASG can access"
  type        = list(string)
}

variable "kms_key_arns" {
  description = "ARNs of KMS keys to be used to decrypt SSM parameters"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "IDs of the VPC security groups to associate"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnets to launch the instances in"
  type        = list(string)
}
