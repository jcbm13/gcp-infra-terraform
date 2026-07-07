# =====================================================================
# 🖥️ INSTANCIA VIRTUAL DE PRUEBAS (En tu subred crea-subred-dev)
# =====================================================================
resource "google_compute_instance" "vm_pruebas" {
  name         = "vm-pruebas-vpn"
  machine_type = "e2-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subred_desarrollo.id
    network_ip = "10.254.1.10" # Tu IP Fija/Estática confirmada

    # Al omitir access_config, la máquina NO tiene IP pública en internet.
  }

  # =====================================================================
  # 🔑 CONFIGURACIÓN DE ACCESO (ELIGE UNA OPCIÓN O USA AMBAS PARA PRUEBAS)
  # =====================================================================
  metadata = {
    # 🔹 OPCIÓN A (LLAVES SSH): Descomenta y reemplaza con tu llave pública si usas PuTTY/MobaXterm
    # ssh-keys = "desarrollador:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ... tu_email@institucion.gob.ec"
  }

  # 🔹 OPCIÓN B (CONTRASEÑA POR DEFECTO VIA SCRIPT DE ARRANQUE)
  # Crea el usuario 'operador' con la clave '#*M1/3deC?2o2-6' (o la que elijas) y habilita el acceso SSH estándar.
  metadata_startup_script = <<EOF
    #!/bin/bash
    # 1. Crear el usuario del sistema si no existe
    if ! id -u operador &>/dev/null; then
      useradd -m -s /bin/bash operador
    fi
    
    # 2. Asignar la contraseña temporal de forma segura
    echo "operador:#*M1/3deC?2o2-6" | chpasswd
    
    # 3. Otorgar permisos de Administrador (Sudo)
    usermod -aG sudo operador
    
    # 4. Modificar la configuración de SSH para permitir autenticación por password
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
    
    # 5. Reiniciar el servicio SSH para aplicar cambios
    systemctl restart sshd
    
    echo "Servidor de desarrollo listo para pruebas VPN con usuario operador" > /var/tmp/status.txt
  EOF
}

# =====================================================================
# 🛡️ REGLA DE FIREWALL INTERNA EN GCP (Permisos para tus redes en tierra)
# =====================================================================
resource "google_compute_firewall" "permitir_desde_redes_tierra" {
  name    = "allow-ssh-ping-from-institutional-networks"
  network = google_compute_network.vpc_network.name

  # Permitir Ping (ICMP)
  allow {
    protocol = "icmp"
  }

  # Permitir SSH (Puerto 22)
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # 🔒 Orígenes permitidos estrictamente limitados a tus segmentos locales
  source_ranges = [
    "10.2.105.0/24",
    "10.2.196.124/32"
  ]
}