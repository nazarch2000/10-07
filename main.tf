terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token = "y0_AtokenyuI7-xFIjc"
  cloud_id = "b1gjpa2s4k3vh5idi0a0"
  folder_id = "b1grrtnnrkhmmjpth8io"
  zone = "ru-central1-b"
}

resource "yandex_lb_target_group" "terraform-1" {
  name   = "terra-1"
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address  = "${yandex_compute_instance.vm-1[0].network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address  = "${yandex_compute_instance.vm-1[1].network_interface.0.ip_address}"
  }
}

resource "yandex_compute_instance" "vm-1" {
  count = 2
  name = "vm${count.index}"
  zone = "ru-central1-b"
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

resource "yandex_lb_network_load_balancer" "terraform-1" {
  name = "test-vm"
listener {
    name = "my-listener"
    port = 80
  }
attached_target_group {
    target_group_id = "${yandex_lb_target_group.terraform-1.id}"
    healthcheck {
      name = "http"
        http_options {
          port = 80
          path = "/"
        }
    }
  }
}
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1[0].network_interface.0.ip_address
}
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1[0].network_interface.0.nat_ip_address
}
output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-1[1].network_interface.0.ip_address
}
output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-1[1].network_interface.0.nat_ip_address
}

