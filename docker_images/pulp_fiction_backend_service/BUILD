load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push")
load("@io_bazel_rules_docker//docker/package_managers:download_pkgs.bzl", "download_pkgs")
load("@io_bazel_rules_docker//docker/package_managers:install_pkgs.bzl", "install_pkgs")
load("//bazel:utils.bzl", "file_container_layer")

file_container_layer(
    name = "pulp_fiction_backend_service_jar",
    srcs = ["//pulp_fiction_backend_service:pulp_fiction_backend_service_deploy.jar"],
    package_dir = "/app",
)

file_container_layer(
    name = "pulp_fiction_backend_service_database_credentials_json_encrypted",
    srcs = ["//secrets:pulp_fiction_backend_service_database_credentials.json.encrypted"],
    package_dir = "/var/pulp_fiction_backend_service/secrets",
)

container_image(
    name = "build_image",
    base = "@java_17_image//image",
    layers = [
        ":pulp_fiction_backend_service_jar",
        ":pulp_fiction_backend_service_database_credentials_json_encrypted"
        ],
    workdir = "/app",
    cmd = "java  -jar pulp_fiction_backend_service_deploy.jar",
    visibility = ["//visibility:public"],
)

container_push(
    name = "push_image",
    format = "Docker",
    image = ":build_image",
    registry = "146956608205.dkr.ecr.us-east-1.amazonaws.com",
    repository = "pulp_fiction/backend_service",
    tag = "$(DOCKER_IMAGE_TAG)",
    visibility = ["//visibility:public"],
)
