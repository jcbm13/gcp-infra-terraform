resource "google_compute_firewall" "permitir_ssh_ping" {
  name    = "allow-ssh-and-ping"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}