data "yandex_compute_image" "ubuntu-jammy" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bingo-db" {
    platform_id        = "standard-v2"
    name = "bingo-db"
#    service_account_id = yandex_iam_service_account.service-accounts["alexeit-catgpt-sa"].id
    resources {
      cores         = 4
      memory        = 4
      core_fraction = 50
    }
    scheduling_policy {
#      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.bingo-static.id}"
      nat = false
      ip_address = "10.10.10.20"
    }
    boot_disk {
      initialize_params {
        type = "network-hdd"
        size = "30"
        image_id = data.yandex_compute_image.ubuntu-jammy.id
      }
    }
    metadata = {
      ssh-keys  = "ubuntu:${file("~/.ssh/yc-test.pub")}"
    }
}
