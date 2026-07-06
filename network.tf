# Crear la red VPC personalizada
resource "google_compute_network" "vpc_network" {
  name                    = "crea-vpc"
  auto_create_subnetworks = false 
}

# Crear una subred dentro de esa VPC (región us-east1 de tu main.tf)
resource "google_compute_subnetwork" "subred_desarrollo" {
  name          = "crea-subred-dev-us-east1"
  ip_cidr_range = "10.254.1.0/24" 
  region        = "us-east1"
  network       = google_compute_network.vpc_network.id
}