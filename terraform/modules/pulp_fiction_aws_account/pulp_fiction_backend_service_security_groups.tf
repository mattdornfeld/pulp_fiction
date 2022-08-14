resource "aws_security_group" "pulp_fiction_backend_service" {
  name        = "pulp_fiction_backend_service"
  description = "Security group for pulp_fiction_backend_service"
  vpc_id      = aws_vpc.pulp_fiction.id
}

resource "aws_security_group" "pulp_fiction_backend_service_ingress" {
  name        = "pulp_fiction_backend_service_ingress"
  description = "Security group for pulp_fiction_backend_service"
  vpc_id      = aws_vpc.pulp_fiction.id

  ingress {
    description     = "Allows traffic from load balancer to pulp_fiction_backend_service"
    protocol        = "tcp"
    from_port       = local.pulp_fiction_backend_service_container_port
    to_port         = local.pulp_fiction_backend_service_container_port
    security_groups = [aws_security_group.pulp_fiction_backend_service_alb.id]
  }
}


resource "aws_security_group" "pulp_fiction_backend_service_aurora" {
  name        = "pulp_fiction_backend_service_aurora"
  description = "Allows inbound access from the pulp_fiction_backend_service to its database"
  vpc_id      = aws_vpc.pulp_fiction.id

  ingress {
    description     = "Allows traffic from pulp_fiction_backend_service to database"
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = [aws_security_group.pulp_fiction_backend_service.id]
  }
}

resource "aws_security_group" "pulp_fiction_backend_service_alb" {
  name   = "pulp_fiction_backend_service_alb"
  vpc_id = aws_vpc.pulp_fiction.id

  ingress {
    description      = "Allows http traffic from internet to load balancer. Load balancer will redirect to https."
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allows https traffic from internet to load balancer"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description     = "Allows traffic from load balancer to pulp_fiction_backend_service"
    protocol        = "tcp"
    from_port       = local.pulp_fiction_backend_service_container_port
    to_port         = local.pulp_fiction_backend_service_container_port
    security_groups = [aws_security_group.pulp_fiction_backend_service.id]
  }
}