# Create a GCP VM instance
resource "google_compute_instance" "kestra_vm" {
  name         = var.kestra_vm_name
  machine_type = var.kestra_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${tls_private_key.ssh_key.public_key_openssh}"
    user-data = file("${path.module}/startup.sh")
  }
  service_account {
    # Google recommends custom service accounts with `cloud-platform` scope with
    # specific permissions granted via IAM Roles.
    # This approach lets you avoid embedding secret keys or user credentials
    # in your instance, image, or app code
    email  = google_service_account.kestra_service_account.email
    scopes = ["cloud-platform"]
  }


  # Allow HTTP/HTTPS traffic
  tags = ["http-server", "https-server"]
}

# Firewall rule for Kestra UI
resource "google_compute_firewall" "kestra-ui" {
  name    = "allow-kestra-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]  # Default Kestra UI port
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Null resource to provisioners for file transfer and remote execution
resource "null_resource" "deploy_kestra" {
  # Trigger a redeploy when any of these changes
  triggers = {
    instance_id = google_compute_instance.kestra_vm.id
  }

  # Wait for VM to be ready and SSH to be available
  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection established'",
      "sudo mkdir -p /opt/kestra",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /opt/kestra"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
      # Add a timeout to ensure we wait for the VM to be fully initialized
      timeout     = "5m"
    }
  }

  # Copy Docker Compose file to the VM
  provisioner "file" {
    source      = var.docker_compose_path
    destination = "/opt/kestra/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  # Copy Dockerfile to the VM
  provisioner "file"{
    source      = var.docker_file_path
    destination = "/opt/kestra/Dockerfile.kestra"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  # Copy any additional files needed (configs, etc.)
  provisioner "file" {
    source      = var.files_dir_path
    destination = "/opt/kestra/files"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  # Copy flows directory to the VM
  provisioner "file" {
    source      = var.flows_dir_path
    destination = "/opt/kestra/flows"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  # Start Docker Compose
  provisioner "remote-exec" {
    inline = [
      "cd /opt/kestra",
      "sudo docker compose up -d"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
    }
  }

  depends_on = [google_compute_instance.kestra_vm]
}