variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "secret_arns" {
  description = "ARNs of SSM Parameter secrets which EC2 can access"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "IDs of the VPC security groups to associate"
  type        = list(string)
}

variable "subnet_id" {
  description = "Subnet to launch the instance in"
  type        = string
}
