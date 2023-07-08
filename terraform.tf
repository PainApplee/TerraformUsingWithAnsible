provider "google" {
  credentials = file ("./accountkey.json")
  project     = "education-357512"
  region      = "us-central1"
}

resource "google_compute_address" "default" {
  name = "monitoring_ip"
}


resource "google_compute_instance" "monitoring" {
  name         = "monitoring"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

boot_disk {
    auto_delete = true
    device_name = "monitoring"

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
  ssh-keys = "ubuntu:${file("<pub_key_path>")}"
}

provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = google_compute_address.default.address
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("prvt_key_path")
    }
  }

  provisioner "local-exec" {
    command = "/bin/bash ./createinventory.sh ${google_compute_address.default.address}"
}

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i ./inventory --private-key <prvt_key_path> -e 'pub_key=<pub_key_path>' <playbook_path>"
  }

}



