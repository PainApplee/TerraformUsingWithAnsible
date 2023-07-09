provider "google" {
  credentials = file ("./accountkey.json")
  project     = "education-357512"
  region      = "us-central1"

}

variable "pub_key" {
  type    = string
  default = "/home/user/.ssh/id_rsa.pub"
}

variable "prvt_key" {
  type    = string
  default = "/home/user/.ssh/id_rsa"
}

variable "ansible_playbook" {
  type    = string
  default = "./PrometheusWithGrafana/playbook.yml"
}


resource "google_compute_address" "default" {
  name = "monitoring-ip"
}


resource "google_compute_instance" "monitoring" {
  name         = "monitoring1"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

boot_disk {
    auto_delete = true
    device_name = "monitoring1"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20230628"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.default.address}"
    }
  }

metadata = {
  ssh-keys = "ubuntu:${file(var.pub_key)}"
}

provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = google_compute_address.default.address
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.prvt_key)
    }
  }

  provisioner "local-exec" {
    command = "/bin/bash ./createinventory.sh ${google_compute_address.default.address}"
}

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i ./inventory --private-key ${var.prvt_key} -e 'pub_key=${var.pub_key}' ${var.ansible_playbook}"
  }

}



