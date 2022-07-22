load("@io_bazel_rules_docker//container:pull.bzl", "container_pull")

def pull_containers():
    container_pull(
        name = "swift_image",
        digest = "sha256:51d04c93a43455cd7070ff8da705805ed8bb340e29c47065fae298a1d90db913",
        registry = "docker.io",
        repository = "library/swift",
        tag = "5.6.2-focal",
    )

    container_pull(
        name = "ubuntu_image",
        digest = "sha256:b2339eee806d44d6a8adc0a790f824fb71f03366dd754d400316ae5a7e3ece3e",
        registry = "docker.io",
        repository = "library/ubuntu",
        tag = "20.04",
    )
