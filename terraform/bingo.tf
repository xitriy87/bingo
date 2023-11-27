#variable "folder_id" {
#  type = string
#}
#
#variable "provider_key_path" {
#  type = string
#}

#locals {
#  folder_id = var.folder_id
#  provider_key_path = var.provider_key_path
locals {
   service-accounts = toset([
    "alexeit-bingo-sa",
    "alexeit-bingo-ig-sa"
  ])
  bingo-sa-roles = toset([
    "container-registry.images.puller",
    "monitoring.editor"
  ])
   bingo-ig-sa-roles = toset([
    "editor"
   ])
}

#resource "yandex_vpc_network" "bingo" {}

#resource "yandex_vpc_subnet" "bingo" {
#  zone           = "ru-central1-a"
#  network_id     = yandex_vpc_network.bingo.id
#  v4_cidr_blocks = ["10.10.10.0/24"]
#  route_table_id = yandex_vpc_route_table.bingo-rt.id
#}

#resource "yandex_vpc_gateway" "nat_bingo_gateway" {
#  name = "bingo-gateway"
#  shared_egress_gateway {}
#}

#resource "yandex_vpc_route_table" "bingo-rt" {
#  name       = "bingo-rt"
#  network_id = yandex_vpc_network.bingo.id
#
#  static_route {
#    destination_prefix = "0.0.0.0/0"
#    gateway_id         = yandex_vpc_gateway.nat_bingo_gateway.id
#  }
#}


##resource "yandex_container_registry" "registry1" {
#  name = "registry1"
#}

resource "yandex_iam_service_account" "service-accounts" {
  for_each = local.service-accounts
  name     = each.key
}
resource "yandex_resourcemanager_folder_iam_member" "bingo-roles" {
  for_each  = local.bingo-sa-roles
  folder_id = local.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.service-accounts["alexeit-bingo-sa"].id}"
  role      = each.key
}

resource "yandex_resourcemanager_folder_iam_member" "bingo-ig-roles" {
  for_each  = local.bingo-ig-sa-roles
  folder_id = local.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.service-accounts["alexeit-bingo-ig-sa"].id}"
  role      = each.key
}

data "yandex_compute_image" "coi" {
  family = "container-optimized-image"
}

#resource "yandex_vpc_security_group" "bingo-sg" {
#  name = "bingo-sg"
#  description = "sg for bingo instance"
#  network_id = "${yandex_vpc_network.bingo.id}"
#
#  ingress {
#    protocol = "TCP"
#    v4_cidr_blocks = ["10.10.10.0/24"]
#    from_port = 0
#    to_port = 65535
#  }
#
#  egress {
#    protocol = "TCP"
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    from_port = 0
#    to_port = 65535
#  }
#}


resource "yandex_compute_instance_group" "bingo-group" {
    name = "bingo-group"
    service_account_id = yandex_iam_service_account.service-accounts["alexeit-bingo-ig-sa"].id
    folder_id = local.folder_id
    depends_on = [
      yandex_resourcemanager_folder_iam_member.bingo-ig-roles
    ]
    instance_template {
      platform_id = "standard-v2"
      service_account_id = yandex_iam_service_account.service-accounts["alexeit-bingo-sa"].id
      resources {
        cores         = 2
        memory        = 1
        core_fraction = 50
      }
      scheduling_policy {
        preemptible = true
      }
      network_interface {
        network_id     = yandex_vpc_network.bingo.id
        subnet_ids = [yandex_vpc_subnet.bingo.id]
        nat = false
      }
      boot_disk {
        initialize_params {
          type = "network-hdd"
          size = "30"
          image_id = data.yandex_compute_image.coi.id
        }
      }
      metadata = {
        user-data = file("./cloud-init-bingo.yaml")
        docker-compose = file("${path.module}/docker-compose.yaml")
        ssh-keys  = "ubuntu:${file("~/.ssh/yc-test.pub")}"
      }
    }
    scale_policy {
      fixed_scale {
        size = 2
      }
    }
    allocation_policy {
      zones = ["ru-central1-a"]
    }
    deploy_policy {
      max_unavailable = 2
      max_creating = 2
      max_expansion = 2
      max_deleting = 2
    }
    health_check {
       interval = 20
       timeout = 15
       unhealthy_threshold = 2
       healthy_threshold = 2
       http_options {
         port = 20061
         path = "/ping"
       }
    }
}
 

output "instances_ip_addr" {
  value =["${yandex_compute_instance_group.bingo-group.instances[0].network_interface[0].ip_address}", "${yandex_compute_instance_group.bingo-group.instances[1].network_interface[0].ip_address}"]
}

