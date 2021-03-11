variable "gcp_sakey" {}
variable "gce_project" {}
variable "gce_region" {}
variable "gce_zone" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key" {}
variable "gce_dns_zone_name" {}
variable "gce_dns_zone" {}

# https://www.terraform.io/docs/providers/google/index.html
provider "google" {
  credentials = file(var.gcp_sakey)
  project     = var.gce_project
  region      = var.gce_region
}

// https://www.terraform.io/docs/providers/google/r/compute_firewall.html
resource "google_compute_firewall" "smu-0" {
  name        = "smu-0"
  network     = "default"
  target_tags = ["smu", "https", "stun", "webrtc"]

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8089"]
  }

  allow {
    protocol = "udp"
    ports    = ["10000-20000"]
  }
}

# https://www.terraform.io/docs/providers/google/d/datasource_compute_address.html
resource "google_compute_address" "smu-0" {
  name = "smu-0"
}

# https://www.terraform.io/docs/providers/google/d/datasource_compute_instance.html
resource "google_compute_instance" "smu-0" {
  name         = "smu-0"
  machine_type = "e2-micro"
  zone         = var.gce_zone
  tags         = ["smu", "https", "stun", "webrtc"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_pub_key}"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.smu-0.address
    }
  }
}

resource "google_dns_record_set" "webrtc" {
  name         = "webrtc.${var.gce_dns_zone}"
  type         = "A"
  ttl          = 300
  managed_zone = var.gce_dns_zone_name
  rrdatas      = [google_compute_instance.smu-0.network_interface[0].access_config[0].nat_ip]
}
