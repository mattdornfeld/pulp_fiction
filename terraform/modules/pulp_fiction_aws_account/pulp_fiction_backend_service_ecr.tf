module "pulp_fiction_ecr_repository_backend_service" {
  source = "./modules/pulp_fiction_ecr_repository"
  name   = "pulp_fiction/backend_service"
}
