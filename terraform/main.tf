
locals {
  fleet_count = 3
  flavour     = "2xCPU-4GB"
  region      = "uk-lon1"
}

resource "upcloud_server" "worker" {
  count    = local.fleet_count
  plan     = local.flavour
  hostname = "node${count.index}"
  zone     = local.region

  template {
    storage = "01000000-0000-4000-8000-000030220200"
    size    = 80
  }

  network_interface {
    type = "public"
  }

  network_interface {
    type                = "private"
    bootable            = false
    source_ip_filtering = false
    ip_address_family   = "IPv4"
    network             = upcloud_network.k8s_vpc.id
    ip_address          = "10.8.0.${count.index + 1}"
  }

  labels = {
    cluster = "homelab"
    env     = "prod"
    node    = "worker${count.index}"
  }

  login {
    keys = data.github_user.kaminek.ssh_keys
  }

  metadata = true
}

resource "upcloud_network" "k8s_vpc" {
  name = "k8s-vpc"
  zone = local.region

  ip_network {
    address            = "10.8.0.0/24"
    dhcp               = false
    dhcp_default_route = false
    family             = "IPv4"
  }
}
