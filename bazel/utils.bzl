load("@io_bazel_rules_docker//container:container.bzl", "container_layer")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

def file_container_layer(name, srcs, package_dir):
    tar_name = name + "_tar"
    pkg_tar(
        name = name + "_tar",
        srcs = srcs,
        package_dir = package_dir
    )

    container_layer(
        name = name,
        tars = [tar_name],
    )
