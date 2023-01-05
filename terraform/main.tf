
locals {
  fleet_count = 3
  flavour     = "2xCPU-4GB"
}

resource "upcloud_server" "worker" {
  count    = local.fleet_count
  plan     = local.flavour
  hostname = "node${count.index}"
  zone     = "uk-lon1"

  template {
    storage = "01000000-0000-4000-8000-000030220200"
    size    = 40
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
