# =====================================================================
# 🚇 INFRAESTRUCTURA HA VPN (High Availability)
# =====================================================================

# 1. El HA VPN Gateway (Enganchado a tu VPC de desarrollo)
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name    = "vpn-gcp-to-office-${var.environment}" # vpn-gcp-to-office-dev
  network = google_compute_network.vpc_network.id
  region  = var.region # Lee "us-east1" de variables.tf
}

# 2. El Cloud Router requerido para el intercambio de tráfico
resource "google_compute_router" "vpn_router" {
  name    = "router-vpn-${var.region}" # router-vpn-us-east1
  region  = var.region
  network = google_compute_network.vpc_network.id
  bgp {
    asn = 65001
  }
}

# 3. Registro de tu Firewall Check Point local en tierra
resource "google_compute_external_vpn_gateway" "office_gateway" {
  name            = "office-checkpoint-gateway-${var.environment}"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"

  interface {
    id         = 0
    ip_address = var.office_checkpoint_ip # Lee "181.112.154.18" de variables.tf
  }
}

# =====================================================================
# 🔒 TÚNELES IPSEC (Para la Alta Disponibilidad de GCP)
# =====================================================================

# Túnel VPN 1 (Interfaz 0)
resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "vpn-tunnel-1-${var.environment}"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.office_gateway.id
  peer_external_gateway_interface = 0
  router                          = google_compute_router.vpn_router.name
  vpn_gateway_interface           = 0
  shared_secret                   = var.vpn_shared_secret # Clave secreta e invisible de variables.tf
  ike_version                     = 2
}

# Túnel VPN 2 (Interfaz 1 - Backup/Redundancia activa)
resource "google_compute_vpn_tunnel" "tunnel2" {
  name                            = "vpn-tunnel-2-${var.environment}"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.office_gateway.id
  peer_external_gateway_interface = 0
  router                          = google_compute_router.vpn_router.name
  vpn_gateway_interface           = 1
  shared_secret                   = var.vpn_shared_secret # Clave secreta e invisible de variables.tf
  ike_version                     = 2
}

# =====================================================================
# 🛣️ RUTAS ESTÁTICAS DINÁMICAS HACIA TIERRA
# =====================================================================

# Genera automáticamente las rutas de alta prioridad (100) para el Túnel 1
resource "google_compute_route" "rutas_tunnel1" {
  count = length(var.vpn_local_subnets)

  name        = "route-to-onprem-${count.index}-via-t1-${var.environment}"
  dest_range  = var.vpn_local_subnets[count.index] # Recorre tus 3 subredes locales de variables.tf
  network     = google_compute_network.vpc_network.name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
  priority    = 100 # Prioridad alta (Ruta principal)
}

# Genera automáticamente las rutas de respaldo (200) para el Túnel 2
resource "google_compute_route" "rutas_tunnel2" {
  count = length(var.vpn_local_subnets)

  name        = "route-to-onprem-${count.index}-via-t2-${var.environment}"
  dest_range  = var.vpn_local_subnets[count.index] # Recorre tus 3 subredes locales de variables.tf
  network     = google_compute_network.vpc_network.name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
  priority    = 200 # Prioridad baja (Ruta de respaldo/failover)
}