terraform {
  backend "s3" {
    bucket = "veecode-homolog-terraform-state"
    key    = "blog-demo-cluster/persistent.tfstate"
    region = "us-east-1"
  }
}