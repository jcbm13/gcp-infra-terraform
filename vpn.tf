# 1. El HA VPN Gateway (Enganchado a tu vpc "crea-vpc")
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name    = "vpn-gcp-to-office-dev"
  network = google_compute_network.vpc_network.id
  region  = "us-east1"
}

# 2. El Cloud Router pasivo requerido por GCP
resource "google_compute_router" "vpn_router" {
  name    = "router-vpn-us-east1"
  region  = "us-east1"
  network = google_compute_network.vpc_network.id
  bgp {
    asn = 65001
  }
}

# 3. Registro de tu Firewall Check Point local
resource "google_compute_external_vpn_gateway" "office_gateway" {
  name            = "office-checkpoint-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"

  interface {
    id         = 0
    ip_address = "181.112.154.18" # Tu IP pública confirmada
  }
}

# 4. Túnel VPN 1 (IKEv2 según tus especificaciones)
resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "vpn-tunnel-1"
  region                          = "us-east1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.office_gateway.id
  peer_external_gateway_interface = 0
  router                          = google_compute_router.vpn_router.name
  vpn_gateway_interface           = 0
  shared_secret                   = "#*M1/3deC?2o2-6" # Tu PSK confirmada
  ike_version                     = 2
}

# 5. Túnel VPN 2 (Para alta disponibilidad del lado de GCP)
resource "google_compute_vpn_tunnel" "tunnel2" {
  name                            = "vpn-tunnel-2"
  region                          = "us-east1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.office_gateway.id
  peer_external_gateway_interface = 0
  router                          = google_compute_router.vpn_router.name
  vpn_gateway_interface           = 1
  shared_secret                   = "#*M1/3deC?2o2-6"
  ike_version                     = 2
}

# =====================================================================
# 🛣️ RUTAS ESTÁTICAS PARA ALCANZAR TUS REDES EN TIERRA
# =====================================================================

# --- Rutas para la red completa 10.2.105.0/24 ---
resource "google_compute_route" "ruta_red_t1" {
  name                = "ruta-hacia-red-10-2-105-t1"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.105.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
  priority            = 100
}

resource "google_compute_route" "ruta_red_t2" {
  name                = "ruta-hacia-red-10-2-105-t2"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.105.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
  priority            = 200
}

# --- Rutas para el host específico 10.2.196.124/32 ---
resource "google_compute_route" "ruta_host_t1" {
  name                = "ruta-hacia-host-10-2-196-124-t1"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.196.124/32"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
  priority            = 100
}

resource "google_compute_route" "ruta_host_t2" {
  name                = "ruta-hacia-host-10-2-196-124-t2"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.196.124/32"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
  priority            = 200
}

resource "google_compute_route" "ruta_red2_t1" {
  name                = "ruta-hacia-host-10-2-140-t1"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.140.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
  priority            = 200
}
resource "google_compute_route" "ruta_red2_t2" {
  name                = "ruta-hacia-host-10-2-140-t2"
  network             = google_compute_network.vpc_network.name
  dest_range          = "10.2.140.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
  priority            = 200
}