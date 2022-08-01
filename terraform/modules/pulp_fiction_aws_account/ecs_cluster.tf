resource "aws_kms_key" "pulp_fiction_ecs_cluster_logging" {
  description             = "pulp_fiction_ecs_cluster_logging"
}

resource "aws_cloudwatch_log_group" "pulp_fiction" {
  name = "ecs/pulp_fiction"
}

resource "aws_ecs_cluster" "pulp_fiction" {
  name = "pulp_fiction"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.pulp_fiction_ecs_cluster_logging.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.pulp_fiction.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.pulp_fiction.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
