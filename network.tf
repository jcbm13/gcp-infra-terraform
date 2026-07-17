# =====================================================================
# RED VPC Y SUBREDES
# =====================================================================

# Crear la red VPC personalizada para el ambiente actual
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name # Lee "crea-vpc-dev" de variables.tf
  auto_create_subnetworks = false 
}

# Crear la subred de desarrollo enlazada a la VPC
resource "google_compute_subnetwork" "subred_desarrollo" {
  # El nombre se genera dinámicamente: "crea-subred-dev-us-east1"
  name          = "crea-subred-${var.environment}-${var.region}" 
  ip_cidr_range = var.subnet_cidr # Lee "10.254.1.0/24" de variables.tf
  region        = var.region      # Lee "us-east1" de variables.tf
  network       = google_compute_network.vpc_network.id
}

# =====================================================================
# 🔌 CONECTOR SERVERLESS (Para conectar Cloud Run con tu VPC)
# =====================================================================

# El conector que permite a tus microservicios de Cloud Run acceder a tu red privada
resource "google_vpc_access_connector" "run_connector" {
  # El nombre se genera dinámicamente: "crea-connector-dev"
  name          = "crea-connector-${var.environment}" 
  region        = var.region # Lee "us-east1" de variables.tf
  
  # Rango de IPs dedicado exclusivamente para el conector de Cloud Run (/28)
  ip_cidr_range = var.serverless_connector_cidr # Lee "10.8.0.0/28" de variables.tf
  
  # Hace referencia directa al nombre del recurso de tu VPC
  network       = google_compute_network.vpc_network.name
  
  min_instances = 2
  max_instances = 3
}