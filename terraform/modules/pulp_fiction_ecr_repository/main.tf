resource "aws_ecr_repository" "pulp_fiction_ecr_repository" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "pulp_fiction_ecr_repository" {
  repository = aws_ecr_repository.pulp_fiction_ecr_repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 10,
            "description": "Keep production images indefinitely",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["latest"],
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 365250
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 20,
            "description": "Delete development images after TTL",
            "selection": {
                "tagStatus": "any",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}