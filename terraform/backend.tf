terraform {
  backend "remote" {
    organization = "kaminek"
    workspaces {
      name = "infrastructure"
    }
  }
}
