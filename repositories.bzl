load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def pulp_fiction_dependencies():
    http_archive(
        name = "io_bazel_rules_kotlin",
        sha256 = "12d22a3d9cbcf00f2e2d8f0683ba87d3823cb8c7f6837568dd7e48846e023307",
        url = "https://github.com/bazelbuild/rules_kotlin/releases/download/v1.5.0/rules_kotlin_release.tgz",
    )

    http_archive(
        name = "com_github_grpc_grpc_kotlin",
        sha256 = "466d33303aac7e825822b402efa3dcfddd68e6f566ed79443634180bb75eab6e",
        strip_prefix = "grpc-kotlin-1.3.0",
        url = "https://github.com/grpc/grpc-kotlin/archive/v1.3.0.tar.gz",
    )

    http_archive(
        name = "build_bazel_rules_swift",
        sha256 = "a2fd565e527f83fb3f9eb07eb9737240e668c9242d3bc318712efa54a7deda97",
        url = "https://github.com/bazelbuild/rules_swift/releases/download/0.27.0/rules_swift.0.27.0.tar.gz",
    )

    http_archive(
        name = "cgrindel_rules_spm",
        sha256 = "ba4310ba33cd1864a95e41d1ceceaa057e56ebbe311f74105774d526d68e2a0d",
        strip_prefix = "rules_spm-0.10.0",
        url = "http://github.com/cgrindel/rules_spm/archive/v0.10.0.tar.gz",
    )

    http_archive(
        name = "build_bazel_rules_apple",
        sha256 = "12865e5944f09d16364aa78050366aca9dc35a32a018fa35f5950238b08bf744",
        url = "https://github.com/bazelbuild/rules_apple/releases/download/0.34.2/rules_apple.0.34.2.tar.gz",
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