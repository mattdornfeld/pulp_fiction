resource "aws_ecs_task_definition" "pulp_fiction_backend_service" {
  family                   = "pulp_fiction_backend_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.pulp_fiction_backend_service_execution_role.arn
  task_role_arn            = aws_iam_role.pulp_fiction_backend_service_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "pulp_fiction_backend_service"
      image     = "146956608205.dkr.ecr.us-east-1.amazonaws.com/pulp_fiction/backend_service"
      essential = true

      environment = [
        {
          name  = "DATABASE_ENDPOINT"
          value = aws_rds_cluster.pulp_fiction_backend_service.endpoint
        }
      ]
      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "us-east-1"
          awslogs-group         = aws_cloudwatch_log_group.pulp_fiction.id
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "pulp_fiction_backend_service" {
  name                 = "pulp_fiction_backend_service"
  cluster              = aws_ecs_cluster.pulp_fiction.id
  task_definition      = aws_ecs_task_definition.pulp_fiction_backend_service.arn
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.egress_all.id,
      aws_security_group.ingress_api.id,
    ]
    subnets = [
      aws_subnet.private_d.id,
      aws_subnet.private_e.id,
    ]
  }

  capacity_provider_strategy {
    # forces replacement
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 100
  }
}
