terraform {
  backend "s3" {
    bucket = "veecode-apr-terraform-state"
    key    = "blog-demo-cluster/persistent.tfstate"
    region = "us-east-1"
  }
}