load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def pulp_fiction_dependencies():
    http_archive(
        name = "io_bazel_rules_kotlin",
        sha256 = "a57591404423a52bd6b18ebba7979e8cd2243534736c5c94d35c89718ea38f94",
        url = "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.6.0/rules_kotlin_release.tgz",
    )

    http_archive(
        name = "com_github_grpc_grpc_kotlin",
        sha256 = "466d33303aac7e825822b402efa3dcfddd68e6f566ed79443634180bb75eab6e",
        strip_prefix = "grpc-kotlin-1.3.0",
        url = "https://github.com/grpc/grpc-kotlin/archive/v1.3.0.tar.gz",
    )

    http_archive(
        name = "com_github_buildbuddy_io_rules_xcodeproj",
        sha256 = "564381b33261ba29e3c8f505de82fc398452700b605d785ce3e4b9dd6c73b623",
        url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.9.0/release.tar.gz",
    )

    http_archive(
        name = "cgrindel_rules_spm",
        sha256 = "03718eb865a100ba4449ebcbca6d97bf6ea78fa17346ce6d55532312e8bf9aa8",
        strip_prefix = "rules_spm-0.11.0",
        url = "https://github.com/cgrindel/rules_spm/archive/v0.11.0.tar.gz",
    )

    http_archive(
        name = "cgrindel_rules_swiftformat",
        sha256 = "f496774f56e8260e277dc17366cf670b55dee3616327a13d2d04bd1b62cdcc88",
        strip_prefix = "rules_swiftformat-0.4.1",
        url = "http://github.com/cgrindel/rules_swiftformat/archive/v0.4.1.tar.gz",
    )

    http_archive(
        name = "rules_jvm_external",
        sha256 = "cd1a77b7b02e8e008439ca76fd34f5b07aecb8c752961f9640dea15e9e5ba1ca",
        strip_prefix = "rules_jvm_external-4.2",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/4.2.zip",
    )

    http_archive(
        name = "io_bazel_rules_docker",
        sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
        urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
    )

    http_archive(
        name = "rules_terraform",
        sha256 = "d330452b845773dec31cb4105bd5ef416f7f32e745a9b67cb14ca203be8a0ccb",
        urls = ["https://github.com/jdreaver/rules_terraform/tarball/e460befbb3d3204e132085020e6b565a224b838e"],
        type = "tar.gz",
        strip_prefix = "jdreaver-rules_terraform-e460bef"
    )
