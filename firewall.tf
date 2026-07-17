# =====================================================================
# 🛡️ REGLAS DE FIREWALL PERIMETRALES (Filtradas por Etiquetas)
# =====================================================================

# Regla para VMs de administración interna o pruebas dentro de la VPC (SSH y Ping)
resource "google_compute_firewall" "permitir_ssh_ping" {
  name    = "allow-ssh-and-ping-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["permitir-ssh-ping-${var.environment}"]
}

# =====================================================================
# 🔌 REGLAS PARA LA COMUNICACIÓN DE SERVICIOS Y BASE DE DATOS (Postgres)
# =====================================================================

# 1. Permitir que los Microservicios (vía el Conector Serverless) accedan a PostgreSQL
resource "google_compute_firewall" "permitir_microservicios_a_db" {
  name        = "allow-run-connector-to-db-${var.environment}"
  description = "Permite que los contenedores de Cloud Run se conecten a la base de datos de manera interna"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"] # Puerto estándar exclusivo de PostgreSQL
  }

  # Origen: Rango CIDR exclusivo del Serverless VPC Connector de Cloud Run
  source_ranges = [var.serverless_connector_cidr] # Toma "10.8.0.0/28"
}

# 2. Permitir que el Administrador de Base de Datos acceda a PostgreSQL desde la VPN (Local)
resource "google_compute_firewall" "permitir_admin_vpn_a_db" {
  name        = "allow-vpn-admins-to-db-${var.environment}"
  description = "Permite a los administradores de la red local gestionar PostgreSQL de forma segura"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"] # Puerto estándar exclusivo de PostgreSQL
  }

  # 🚀 DINÁMICO: Origen tomado desde la variable centralizada
  source_ranges = var.vpn_local_subnets
}

# 3. Permitir tráfico de monitoreo y pruebas generales desde la VPN hacia la VPC
resource "google_compute_firewall" "permitir_pruebas_diagnostico_vpn" {
  name        = "allow-diagnostics-from-vpn-${var.environment}"
  description = "Permite ICMP (ping) y HTTP/HTTPS hacia recursos internos de la VPC desde redes locales"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp" # Para poder hacer ping a servidores de prueba en GCP
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"] # Tráfico web/REST estándar para pruebas directas a microservicios
  }

  # 🚀 DINÁMICO: Origen tomado desde la variable centralizada
  source_ranges = var.vpn_local_subnets
}