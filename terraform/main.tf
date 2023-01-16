
locals {
  fleet_count        = 3
  flavour            = "2xCPU-4GB"
  region             = "uk-lon1"
  cloudflare_zone_id = data.sops_file.secrets.data.cloudflare_zone_id
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
    ip_address          = "10.32.0.${format("%d", count.index + 100)}"
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

resource "upcloud_server_group" "main" {
  title         = "cluster"
  anti_affinity = true
  labels = {
    cluster = "homelab"
    env     = "prod"
  }
  members = upcloud_server.worker[*].id
}

resource "upcloud_network" "k8s_vpc" {
  name = "k8s-vpc"
  zone = local.region

  ip_network {
    address            = "10.32.0.0/24"
    dhcp               = true
    dhcp_default_route = false
    family             = "IPv4"
  }
}

resource "cloudflare_record" "nodes" {
  count   = local.fleet_count
  zone_id = local.cloudflare_zone_id
  name    = "node${count.index}.cluster"
  value   = upcloud_server.worker[count.index].network_interface[0].ip_address
  type    = "A"
}

resource "cloudflare_record" "cluster" {
  zone_id = local.cloudflare_zone_id
  name    = "cluster"
  type    = "A"
  value   = upcloud_server.worker[*].network_interface[0].ip_address
}
