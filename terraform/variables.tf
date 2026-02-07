# --- Globals ---
variable "project_name" {
  description = "Project name for resource naming"
  type = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
  default     = "eu-west-2a"
}

# --- SSM Parameter Store - Secrets ---
# MQTT Secrets - Sensor
variable "mqtt_sensor_username" {
  description = "Username for MQTT sensor (Raspberry Pi)"
  type        = string
  default     = "pi_sensor"
  sensitive   = true
}

variable "mqtt_sensor_password" {
  description = "Password for MQTT sensor (Raspberry Pi)"
  type        = string
  sensitive   = true
}

# MQTT Secrets - Telegraf
variable "mqtt_telegraf_username" {
  description = "Username for MQTT Telegraf subscriber"
  type        = string
  default     = "telegraf"
  sensitive   = true
}

variable "mqtt_telegraf_password" {
  description = "Password for MQTT Telegraf subscriber"
  type        = string
  sensitive   = true
}

# TimescaleDB Secrets - Telegraf
variable "timescaledb_telegraf_username" {
  description = "Username for TimescaleDB Telegraf user"
  type        = string
  default     = "telegraf"
  sensitive   = true
}

variable "timescaledb_telegraf_password" {
  description = "Password for TimescaleDB Telegraf user"
  type        = string
  sensitive   = true
}

# TimescaleDB Secrets - Grafana
variable "timescaledb_grafana_username" {
  description = "Username for TimescaleDB Grafana user"
  type        = string
  default     = "grafana"
  sensitive   = true
}

variable "timescaledb_grafana_password" {
  description = "Password for TimescaleDB Grafana user"
  type        = string
  sensitive   = true
}

# Grafana Secrets
variable "grafana_admin_username" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

# Tailscale
variable "tailscale_auth_key" {
  description = "Tailscale ephemeral auth key for EC2 instance"
  type        = string
  sensitive   = true
}
