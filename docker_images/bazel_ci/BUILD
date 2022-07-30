load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push", "container_layer")
load("@io_bazel_rules_docker//docker/package_managers:download_pkgs.bzl", "download_pkgs")
load("@io_bazel_rules_docker//docker/package_managers:install_pkgs.bzl", "install_pkgs")
load("//bazel:utils.bzl", "file_container_layer")

container_image(
    name = "base_image",
    base = "@circleci_base_image//image",
    user = "root",
)

download_pkgs(
    name = "download_packages",
    image_tar = ":base_image.tar",
    packages = [
        "awscli",
        "openjdk-17-jdk",
    ],
)

install_pkgs(
    name = "install_packages",
    image_tar = ":base_image.tar",
    installables_tar = ":download_packages.tar",
    output_image_name = "pulp_fiction_build_java_image",
)

file_container_layer(
    name = "bazelisk",
    srcs = ["@bazelisk_linux_amd64//file"],
    package_dir = "/usr/local/bin",
)

file_container_layer(
    name = "login_to_ecr",
    srcs = ["//sbin:login_to_ecr"],
    package_dir = "/usr/local/bin",
)

container_image(
    name = "build_image",
    base = ":install_packages",
    layers = [":bazelisk", ":login_to_ecr"],
    visibility = ["//visibility:public"],
)

container_push(
    name = "push_image",
    format = "Docker",
    image = ":build_image",
    registry = "146956608205.dkr.ecr.us-east-1.amazonaws.com",
    repository = "pulp_fiction/bazel_ci",
    tag = "$(DOCKER_IMAGE_TAG)",
    visibility = ["//visibility:public"],
)
