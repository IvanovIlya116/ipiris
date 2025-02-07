# Блок для указания требуемых провайдеров
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.95" # Укажите актуальную версию провайдера
    }
  }
}

# Настройка провайдера Yandex Cloud
provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Создание облачной сети
resource "yandex_vpc_network" "network" {
  name = "bookstore-network"
}

# Создание подсети
resource "yandex_vpc_subnet" "subnet" {
  name           = "bookstore-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

# Чтение публичного SSH-ключа
data "local_file" "ssh_public_key" {
  filename = "${path.module}/ssh_keys/id_rsa.pub"
}

# Создание виртуальной машины
resource "yandex_compute_instance" "vm" {
  name        = "bookstore-vm"
  platform_id = "standard-v3"
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd86idv7gmqapoeiq5ld" # ID образа Ubuntu 22.04 LTS
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<-EOF
                #cloud-config
                users:
                  - name: ipiris
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ${data.local_file.ssh_public_key.content}
                runcmd:
                  - sudo apt update && sudo apt install -y docker.io
                  - sudo systemctl start docker
                  - sudo systemctl enable docker
                  - sudo docker run -d -p 80:80 jmix/jmix-bookstore
                EOF
  }
}
