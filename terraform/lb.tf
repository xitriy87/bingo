
resource "yandex_compute_instance" "bingo-lb" {
    platform_id        = "standard-v2"
    name = "bingo-lb"
#    service_account_id = yandex_iam_service_account.service-accounts["alexeit-catgpt-sa"].id
    resources {
      cores         = 2
      memory        = 1
      core_fraction = 50
    }
    scheduling_policy {
#      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.bingo-static.id}"
      nat = true
      #ip_address = "10.10.10.10"
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

output "bingo-lb"  {
  value = "${yandex_compute_instance.bingo-lb.network_interface[0].ip_address}"
}
