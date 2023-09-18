provider "google" {
  project = "proj-id" #Your project id
  region  = "europe-central2" # choose your region 
  zone    = "europe-central2-a" # choose your zone
}

locals {
  project_id = "proj-id" #Your project id
  network    = "default" 
  image      = "ubuntu-2204-jammy-v20230829" #OS image
  ssh_user   = "ssh_user"  # ssh user
  ssh_key    = "${local.ssh_user}:${trimspace(file("~/.ssh/id_rsa.pub"))}"
}

resource "google_compute_address" "default" {
  name = "terraform-static-ip"
}

resource "google_compute_instance" "default" {
  name         = "terraform-instance" #inctance name
  machine_type = "custom-4-8192" #Your machine type

  boot_disk {
    initialize_params {
      image = local.image
      size  = 50 # Vm disk size
    }
  }

  network_interface {
    network = local.network

    access_config {
      nat_ip = google_compute_address.default.address
    }
  }

  metadata = {
    ssh-keys = local.ssh_key
  }
}
output "instance_external_ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
  description = "The external IP of the created instance."
}