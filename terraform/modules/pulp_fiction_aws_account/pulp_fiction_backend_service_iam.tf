data "aws_iam_policy_document" "pulp_fiction_backend_service_execution_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "pulp_fiction_backend_service_execution_role" {
  role       = aws_iam_role.pulp_fiction_backend_service_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "pulp_fiction_backend_service_execution_role" {
  name               = "pulp_fiction_backend_service_execution_role"
  assume_role_policy = data.aws_iam_policy_document.pulp_fiction_backend_service_execution_role.json
}

data "aws_iam_policy_document" "pulp_fiction_backend_service_task_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "pulp_fiction_backend_service_task_role" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.pulp_fiction_backend_service_secrets_encryption.arn,
    ]
  }
}

resource "aws_iam_policy" "pulp_fiction_backend_service_task_role" {
  name   = "pulp_fiction_backend_service_task_role"
  policy = data.aws_iam_policy_document.pulp_fiction_backend_service_task_role.json

}

resource "aws_iam_role_policy_attachment" "pulp_fiction_backend_service_task_role" {
  role       = aws_iam_role.pulp_fiction_backend_service_task_role.name
  policy_arn = aws_iam_policy.pulp_fiction_backend_service_task_role.arn
}

resource "aws_iam_role" "pulp_fiction_backend_service_task_role" {
  name               = "pulp_fiction_backend_service_task_role"
  assume_role_policy = data.aws_iam_policy_document.pulp_fiction_backend_service_task_assume_role_policy.json
}
