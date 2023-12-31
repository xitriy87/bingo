
resource "yandex_compute_instance" "bingo-ansible" {
    platform_id        = "standard-v2"
    name = "bingo-ansible"
#    service_account_id = yandex_iam_service_account.service-accounts["alexeit-catgpt-sa"].id
    resources {
      cores         = 2
      memory        = 1
      core_fraction = 5
    }
    scheduling_policy {
#      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.bingo.id}"
      nat = true
    }
    boot_disk {
      initialize_params {
        type = "network-hdd"
        size = "30"
        image_id = data.yandex_compute_image.ubuntu-jammy.id
      }
    }
    metadata = {
      user-data = file("${path.module}/cloud-init.yaml")
      ssh-keys  = "ubuntu:${file("~/.ssh/yc-test.pub")}"
    }
}
