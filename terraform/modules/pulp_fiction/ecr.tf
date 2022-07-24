resource "aws_ecr_repository" "pulp_fiction_backend_service" {
  name                 = "pulp_fiction_backend_service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "pulp_fiction_java_ci" {
  name                 = "pulp_fiction_java_ci"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
