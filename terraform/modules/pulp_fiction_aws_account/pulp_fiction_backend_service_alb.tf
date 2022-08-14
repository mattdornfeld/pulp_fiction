resource "aws_lb" "pulp_fiction" {
  name                       = "pulp-fiction"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.pulp_fiction_backend_service_alb.id]
  subnets                    = local.public_subnet_ids
  enable_deletion_protection = true
}

resource "aws_alb_target_group" "pulp_fiction_backend_service" {
  name             = "pulp-fiction-backend-service"
  port             = local.pulp_fiction_backend_service_container_port
  protocol         = "HTTP"
  protocol_version = "GRPC"
  vpc_id           = aws_vpc.pulp_fiction.id
  target_type      = "ip"

  health_check {
    path = "/grpc.health.v1.Health/Check"
    matcher = "0-99"
  }
}

resource "aws_alb_listener" "pulp_fiction_https" {
  load_balancer_arn = aws_lb.pulp_fiction.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.pulp_fiction_milkshake_domain.arn

  default_action {
    target_group_arn = aws_alb_target_group.pulp_fiction_backend_service.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "pulp_fiction_http" {
  load_balancer_arn = aws_lb.pulp_fiction.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
