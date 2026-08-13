variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment deve ser 'dev' ou 'prod'."
  }
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fraud-detector"
}

variable "alert_email" {
  description = "Email para receber alertas de fraude (apenas produção)"
  type        = string
  default     = "alerts@example.com"
  sensitive   = true
}