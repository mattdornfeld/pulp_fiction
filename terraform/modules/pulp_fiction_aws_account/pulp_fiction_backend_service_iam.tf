data "aws_iam_policy_document" "pulp_fiction_backend_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pulp_fiction_backend_service" {
  name               = "pulp_fiction_backend_service"
  assume_role_policy = data.aws_iam_policy_document.pulp_fiction_backend_service.json
}

resource "aws_iam_role_policy_attachment" "pulp_fiction_backend_service_execution_role" {
  role       = aws_iam_role.pulp_fiction_backend_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
