provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "pulp-fiction-terraform-state"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

module "pulp_fiction" {
  source = "./modules/pulp_fiction"
}
