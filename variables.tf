# =====================================================================
# 📌 VARIABLES GLOBALES Y DE ENTORNO
# =====================================================================

variable "project_id" {
  type        = string
  description = "El ID único de tu proyecto de GCP para el ambiente de desarrollo."
  default     = "mec-001-dev"
}

variable "region" {
  type        = string
  description = "Región física de GCP para el despliegue de infraestructura."
  default     = "us-east1"
}

variable "environment" {
  type        = string
  description = "Identificador del entorno de trabajo (valores permitidos: dev, uat, prd)."
  default     = "dev"

  # Validación estricta para evitar errores tipográficos en el pipeline
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "El valor del entorno debe ser estrictamente 'dev', 'uat' o 'prd'."
  }
}

# =====================================================================
# 🔌 CONFIGURACIÓN DE RED (VPC, Subredes y Conector)
# =====================================================================

variable "vpc_name" {
  type        = string
  description = "Nombre de la red VPC personalizada para el ambiente actual."
  default     = "crea-vpc-dev"
}

variable "subnet_cidr" {
  type        = string
  description = "Rango de direcciones IP para la subred de desarrollo de CREA."
  default     = "10.254.1.0/24"
}

variable "serverless_connector_cidr" {
  type        = string
  description = "Rango CIDR (/28) exclusivo para el conector de Cloud Run. No debe colisionar con la subred principal."
  default     = "10.8.0.0/28"
}

# =====================================================================
# 🏢 CONECTIVIDAD LOCAL (VPN Check Point)
# =====================================================================

variable "office_checkpoint_ip" {
  type        = string
  description = "IP pública del Firewall Check Point en la oficina Planta Central."
  default     = "181.112.154.18"
}

variable "vpn_shared_secret" {
  type        = string
  description = "Clave pre-compartida (Pre-Shared Key) para levantar de forma segura los túneles VPN."
  sensitive   = true # Evita que la clave secreta se imprima en pantalla o logs de ejecución
  default     = "#*M1/3deC?2o2-6"
}

variable "vpn_local_subnets" {
  type        = list(string)
  description = "Lista de subredes y direcciones IP de la red local autorizadas para acceder a la VPC mediante la VPN."
  default     = [
    "10.2.105.0/24",
    "10.2.140.0/24",
    "10.2.196.124/32"
  ]
}

variable "private_services_cidr" {
  type        = string
  description = "Rango de IPs internas exclusivo para el Peering de bases de datos y servicios de GCP. Debe ser obligatoriamente un rango /16."
  default     = "10.255.0.0" # Cambia esto si colisiona con alguna de tus subredes locales
}