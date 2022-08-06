resource "aws_security_group" "pulp_fiction_backend_service" {
  name        = "pulp_fiction_backend_service"
  description = "Security group for pulp_fiction_backend_service"
  vpc_id      = aws_vpc.pulp_fiction.id
}

resource "aws_security_group" "pulp_fiction_backend_service_aurora" {
  name        = "pulp_fiction_backend_service_aurora"
  description = "Allows inbound access from the pulp_fiction_backend_service to its database"
  vpc_id      = aws_vpc.pulp_fiction.id

  ingress {
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = ["${aws_security_group.pulp_fiction_backend_service.id}"]
  }
}
