data "aws_kms_secrets" "pulp_fiction_backend_service_database_credentials" {
  secret {
    name    = "credentials"
    payload = file("${abspath(path.root)}/pulp_fiction_backend_service_database_credentials.yml.encrypted")
  }
}

locals {
  pulp_fiction_backend_service_database_credentials = yamldecode(data.aws_kms_secrets.pulp_fiction_backend_service_database_credentials.plaintext["credentials"])
}

resource "aws_rds_cluster" "pulp_fiction_backend_service" {
  cluster_identifier = "pulp-fiction-backend-service"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "13.6"
  database_name      = "pulpfiction_backend_service"
  master_username    = local.pulp_fiction_backend_service_database_credentials.username
  master_password    = local.pulp_fiction_backend_service_database_credentials.password

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "pulp_fiction_backend_service" {
  cluster_identifier = aws_rds_cluster.pulp_fiction_backend_service.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.pulp_fiction_backend_service.engine
  engine_version     = aws_rds_cluster.pulp_fiction_backend_service.engine_version
}
