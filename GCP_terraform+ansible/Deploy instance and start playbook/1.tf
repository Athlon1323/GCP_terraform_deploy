provider "google" {
  project = local.project_id #Your project id
  region  = "europe-central2" # choose your region 
  zone    = "europe-central2-a" # choose your zone
}

locals {
  project_id = "main-396613" #Your project id
  network    = "default" 
  image      = "ubuntu-2204-jammy-v20230829" #OS image
  ssh_user   = "keskus"  # ssh user
  ssh_key    = "${local.ssh_user}:${trimspace(file("~/.ssh/keskus.pub"))}"
  zone    = "europe-central2-a"
  private_key = file("~/.ssh/keskus")
  private_key_path = "~/.ssh/keskus"
}

resource "google_compute_address" "default" {
  name = "terraform-stat ic-ip"
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
resource "google_compute_instance" "default" {
  name         = "nginx-ans-ter"
  machine_type = "e2-micro" #Your machine type
  zone         = local.zone

  boot_disk {
    initialize_params {
      image = local.image
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
  
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'",
    "sudo apt update",
    "sudo apt install ansible -y"
    ]
    
    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}, --private-key ${local.private_key_path} nginx.yaml"
  }

}
output "instance_external_ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
  description = "The external IP of the created instance."
}
