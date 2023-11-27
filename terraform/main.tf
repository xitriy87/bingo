terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = local.provider_key_path
  folder_id                = local.folder_id
  zone                     = "ru-central1-a"
}

variable "folder_id" {
  type = string
}

variable "provider_key_path" {
  type = string
}

locals {
  folder_id = var.folder_id
  provider_key_path = var.provider_key_path
}
