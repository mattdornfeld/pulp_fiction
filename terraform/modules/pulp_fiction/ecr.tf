module "pulp_fiction_ecr_repository_bazel_ci" {
  source = "../pulp_fiction_ecr_repository"
  name   = "pulp_fiction/bazel_ci"
}

module "pulp_fiction_ecr_repository_backend_service" {
  source = "../pulp_fiction_ecr_repository"
  name   = "pulp_fiction/backend_service"
}
