resource "aws_s3_bucket" "pulp_fiction_terraform_state" {
  bucket = "pulp-fiction-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "pulp_fiction_content_data" {
  bucket = "pulp-fiction-content-data"

  lifecycle {
    prevent_destroy = true
  }
}
