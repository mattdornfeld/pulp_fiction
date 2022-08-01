resource "aws_s3_bucket" "pulp_fiction_terraform_state" {
  bucket = "pulp-fiction-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}
