data "local_file" "defaults" {
  filename = "${path.module}/config/defaults.yml"
}

locals {
  config = yamldecode(data.local_file.defaults.content)
}
