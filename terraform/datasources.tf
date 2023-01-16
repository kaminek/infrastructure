data "github_user" "kaminek" {
  username = "kaminek"
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}
