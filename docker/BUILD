load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("@io_bazel_rules_docker//docker/package_managers:download_pkgs.bzl", "download_pkgs")
load("@io_bazel_rules_docker//docker/package_managers:install_pkgs.bzl", "install_pkgs")
load("@rules_pkg//:pkg.bzl", "pkg_tar")


download_pkgs(
    name = "download_packages",
    image_tar = "@ubuntu_image//image",
    packages = [
        "openjdk-17-jdk",
    ],
)

install_pkgs(
    name = "install_packages",
    image_tar = "@ubuntu_image//image",
    installables_tar = ":download_packages.tar",
    output_image_name = "pulp_fiction_build_java_image",
)

pkg_tar(
    name = "bin_bazelisk_tar",
    srcs = ["@bazelisk_linux_amd64//file"],
    package_dir = "/bin",
)

container_image(
    name = "install_packages_wrapper",
    base = ":install_packages.tar",
    tars = [":bin_bazelisk_tar"],
    cmd = ["bash"]
)
