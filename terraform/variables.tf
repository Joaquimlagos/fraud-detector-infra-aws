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
  description = "Nome do projeto, usado como prefixo em todos os recursos para evitar colisão de nomes com outros projetos na mesma conta."
  type        = string
  default     = "fraud-detector"
}

variable "alert_email" {
  description = "Email para receber alertas de fraude. Ativo em todos os ambientes (inclusive dev) para permitir validar o fluxo ponta a ponta antes de produção."
  type        = string
  sensitive   = true
}
