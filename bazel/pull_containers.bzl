load("@io_bazel_rules_docker//container:pull.bzl", "container_pull")

def pull_containers():
    container_pull(
        name = "circleci_base_image",
        registry = "docker.io",
        repository = "cimg/base",
        tag = "stable",
    )

    container_pull(
        name = "java_17_image",
        registry = "docker.io",
        repository = "eclipse-temurin",
        tag = "17-jre",
    )
