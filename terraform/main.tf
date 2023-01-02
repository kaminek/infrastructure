
locals {
  fleet_count = 3
  flavour     = "2xCPU-4GB"
}

resource "upcloud_server" "worker" {
  count    = local.fleet_count
  plan     = local.flavour
  hostname = "worker${count.index}"
  zone     = "uk-lon1"

  template {
    storage = "Ubuntu Server 22.04 LTS (Jammy Jellyfish)"
  }

  network_interface {
    type = "public"
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
