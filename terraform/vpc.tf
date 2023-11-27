resource "yandex_vpc_network" "bingo" {}

resource "yandex_vpc_subnet" "bingo" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bingo.id
  v4_cidr_blocks = ["10.10.100.0/24"]
  route_table_id = yandex_vpc_route_table.bingo-rt.id
}

resource "yandex_vpc_subnet" "bingo-static" {
  zone	 	 = "ru-central1-a"
  network_id     = yandex_vpc_network.bingo.id
  v4_cidr_blocks = ["10.10.10.0/24"]
  route_table_id = yandex_vpc_route_table.bingo-rt.id
}

resource "yandex_vpc_gateway" "nat_bingo_gateway" {
  name = "bingo-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "bingo-rt" {
  name       = "bingo-rt"
  network_id = yandex_vpc_network.bingo.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_bingo_gateway.id
  }
}

resource "yandex_vpc_security_group" "bingo-sg" {
  name = "bingo-sg"
  description = "sg for bingo instance"
  network_id = "${yandex_vpc_network.bingo.id}"

  ingress {
    protocol = "TCP"
    v4_cidr_blocks = ["10.10.10.0/24","10.10.100.0/24"]
    from_port = 0
    to_port = 65535
  }

  egress {
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 65535
  }
}


