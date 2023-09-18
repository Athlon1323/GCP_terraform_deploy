locals {
  project_id = "main-396613" #Your project id
  network    = "default" 
  image      = "ubuntu-2204-jammy-v20230829" #OS image
  ssh_user   = "keskus"  # ssh user
  ssh_key    = "${local.ssh_user}:${trimspace(file("~/.ssh/keskus.pub"))}"
  zone    = "europe-central2-a"
  private_key = file("~/.ssh/keskus")
  private_key_path = "~/.ssh/keskus"
  region  = "europe-central2"
}
provider "google" {
  project = local.project_id 
  region  = local.region  
  zone    = local.zone
}
resource "google_compute_firewall" "web" {
  name    = "web-access"
  network = local.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
    source_ranges           = ["0.0.0.0/0"]
}

resource "google_compute_instance" "web_servers" {
  count        = 3
  name         = "nginx-ans-ter-${count.index + 1}"
  machine_type = "f1-micro" 
  zone         = local.zone

  boot_disk {
    initialize_params {
      image = local.image
    }
  }

  network_interface {
    network = local.network
    access_config {
    }
  }
  metadata = {
    ssh-keys = local.ssh_key
  }
}

output "web_server_ips" {
  value = [for instance in google_compute_instance.web_servers : instance.network_interface[0].access_config[0].nat_ip]
}
