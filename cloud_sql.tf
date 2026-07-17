# =====================================================================
# 🌐 CONEXIÓN PRIVADA PARA SERVICIOS (Private Services Access)
# =====================================================================

# 1. Reservar un rango de IPs interno de tu VPC exclusivo para las bases de datos
# Consume dinámicamente la IP base desde variables.tf (ej: 10.255.0.0)
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.private_services_cidr # Toma "10.255.0.0" de variables.tf
  prefix_length = 16                        # Google exige que sea /16 obligatoriamente
  network       = google_compute_network.vpc_network.id
}

# 2. Crear la conexión privada (Peering) entre tu VPC y los servicios de Google
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# =====================================================================
# 🗄️ INSTANCIA DE CLOUD SQL (PostgreSQL Privada)
# =====================================================================

resource "google_sql_database_instance" "postgres_instance" {
  name             = "crea-postgres-${var.environment}" # crea-postgres-dev
  database_version = "POSTGRES_15"                      # Versión estable recomendada
  region           = var.region

  # ⚠️ Seguridad crítica: Esperar a que la conexión de red interna esté establecida antes de crear la BD
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    # Tamaño de la máquina para desarrollo (Económica)
    tier = "db-f1-micro" 

    # Configuración de Red
    ip_configuration {
      ipv4_enabled    = false # DESACTIVA por completo la IP pública
      private_network = google_compute_network.vpc_network.id # Obliga a usar la red privada
    }

    # Recomendación para Dev: Desactivar backups automatizados para ahorrar espacio y costos innecesarios
    backup_configuration {
      enabled = false
    }
  }
}

# Crear la base de datos lógica por defecto para tus microservicios
resource "google_sql_database" "crea_database" {
  name     = "crea_db_${var.environment}" # crea_db_dev
  instance = google_sql_database_instance.postgres_instance.name
}

# =====================================================================
# 🔑 SEGURIDAD, LLAVES Y SECRET MANAGER
# =====================================================================

# 1. Generar una contraseña aleatoria de 16 caracteres altamente segura
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Crear el usuario administrador en PostgreSQL utilizando la contraseña generada
resource "google_sql_user" "db_admin" {
  name     = "crea_admin_${var.environment}" # crea_admin_dev
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.db_password.result
}

# 3. Crear el secreto "contenedor" en Secret Manager para guardar la clave
resource "google_secret_manager_secret" "db_secret_key" {
  secret_id = "crea-db-password-${var.environment}" # crea-db-password-dev
  
  replication {
    auto {} # Réplica automática gestionada por Google
  }
}

# 4. Guardar físicamente la contraseña segura generada por Terraform en el Secreto
resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_secret_key.id
  secret_data = random_password.db_password.result
}