data "yandex_compute_image" "ubuntu-jammy" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bingo-db" {
    platform_id        = "standard-v2"
    name = "bingo-db"
#    service_account_id = yandex_iam_service_account.service-accounts["alexeit-catgpt-sa"].id
    resources {
      cores         = 2
      memory        = 2
      core_fraction = 50
    }
    scheduling_policy {
      preemptible = false
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.bingo-static.id}"
      nat = false
      ip_address = "10.10.10.20"
      security_group_ids = [yandex_vpc_security_group.db-sg.id,yandex_vpc_security_group.ssh-sg.id]
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
