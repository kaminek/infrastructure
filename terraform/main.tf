
locals {
  fleet_count        = 3
  flavour            = "2xCPU-4GB"
  region             = "uk-lon1"
  cloudflare_zone_id = data.sops_file.secrets.data.cloudflare_zone_id
}

resource "upcloud_server" "node" {
  count    = local.fleet_count
  plan     = local.flavour
  hostname = "node${count.index}"
  zone     = local.region
  firewall = true

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
    node    = "node${count.index}"
  }

  login {
    keys = data.github_user.kaminek.ssh_keys
  }

  metadata = true
}

resource "upcloud_server_group" "main" {
  title                = "cluster"
  anti_affinity_policy = "strict"
  labels = {
    cluster = "homelab"
    env     = "prod"
  }
  members = upcloud_server.node[*].id
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
  value   = upcloud_server.node[count.index].network_interface[0].ip_address
  type    = "A"
}

resource "cloudflare_record" "cluster" {
  count   = local.fleet_count
  zone_id = local.cloudflare_zone_id
  name    = "cluster"
  value   = upcloud_server.node[count.index].network_interface[0].ip_address
  type    = "A"
}

resource "upcloud_firewall_rules" "nodes" {
  count     = local.fleet_count
  server_id = upcloud_server.node[count.index].id

  firewall_rule {
    action                 = "accept"
    comment                = "Allow SSH"
    destination_port_start = "22"
    destination_port_end   = "22"
    direction              = "in"
    family                 = "IPv4"
    protocol               = "tcp"
    source_address_start   = data.sops_file.secrets.data.allowed_ip
    source_address_end     = data.sops_file.secrets.data.allowed_ip
  }

  firewall_rule {
    action                 = "accept"
    comment                = "Allow K8s api server"
    destination_port_start = "6443"
    destination_port_end   = "6443"
    direction              = "in"
    family                 = "IPv4"
    protocol               = "tcp"
    source_address_start   = data.sops_file.secrets.data.allowed_ip
    source_address_end     = data.sops_file.secrets.data.allowed_ip
  }

  firewall_rule {
    action               = "accept"
    comment              = "Allow DNSoUDP"
    source_port_start    = "53"
    source_port_end      = "53"
    direction            = "in"
    family               = "IPv4"
    protocol             = "udp"
    source_address_start = "1.1.1.1"
    source_address_end   = "1.1.1.1"
  }

  firewall_rule {
    action                 = "accept"
    comment                = "Allow HTTPS traffic"
    destination_port_start = "443"
    destination_port_end   = "443"
    direction              = "in"
    family                 = "IPv4"
    protocol               = "tcp"
  }

  firewall_rule {
    action    = "drop"
    direction = "in"
  }

  firewall_rule {
    action    = "accept"
    direction = "out"
  }
}
