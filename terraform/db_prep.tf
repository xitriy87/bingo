resource "yandex_compute_instance" "bingo-db-prep" {
    platform_id        = "standard-v2"
    service_account_id = yandex_iam_service_account.service-accounts["alexeit-bingo-sa"].id
    resources {
      cores         = 2
      memory        = 1
      core_fraction = 5
    }
    scheduling_policy {
      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.bingo.id}"
      nat = false
    }
    boot_disk {
      initialize_params {
        type = "network-hdd"
        size = "20"
        image_id = data.yandex_compute_image.coi.id
      }
    }
    metadata = {
      #user-data = file("./cloud-init.yaml")
      docker-compose = file("${path.module}/docker-compose-prep.yaml")
      ssh-keys  = "ubuntu:${file("~/.ssh/ansible_rsa.pub")}"
    }
}
