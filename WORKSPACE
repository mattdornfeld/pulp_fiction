#workspace(name = "pulp_fiction")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "a2fd565e527f83fb3f9eb07eb9737240e668c9242d3bc318712efa54a7deda97",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/0.27.0/rules_swift.0.27.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

http_archive(
    name = "cgrindel_rules_spm",
    sha256 = "ba4310ba33cd1864a95e41d1ceceaa057e56ebbe311f74105774d526d68e2a0d",
    strip_prefix = "rules_spm-0.10.0",
    urls = [
        "http://github.com/cgrindel/rules_spm/archive/v0.10.0.tar.gz",
    ],
)

load(
    "@cgrindel_rules_spm//spm:deps.bzl",
    "spm_rules_dependencies",
)

spm_rules_dependencies()

http_archive(
    name = "rules_proto",
    sha256 = "66bfdf8782796239d3875d37e7de19b1d94301e8972b3cbd2446b332429b4df1",
    strip_prefix = "rules_proto-4.0.0",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0.tar.gz",
        "https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0.tar.gz",
    ],
)
load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
rules_proto_dependencies()
rules_proto_toolchains()

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "12865e5944f09d16364aa78050366aca9dc35a32a018fa35f5950238b08bf744",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/0.34.2/rules_apple.0.34.2.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load("@cgrindel_rules_spm//spm:defs.bzl", "spm_pkg", "spm_repositories")

spm_repositories(
    name = "swift_pkgs",
    platforms = [
        ".macOS(.v10_15)",
    ],
    dependencies = [
        spm_pkg(
            "https://github.com/apple/swift-log.git",
            exact_version = "1.4.2",
            products = ["Logging"],
        ),
        spm_pkg(
            "https://github.com/stephencelis/SQLite.swift.git",
            exact_version = "0.13.3",
            products = ["SQLite"],
        ),
        spm_pkg(
            "https://github.com/pointfreeco/swift-composable-architecture.git",
            exact_version = "0.34.0",
            products = ["ComposableArchitecture"],
        ),
    ],
)

http_archive(
    name = "cgrindel_rules_swiftformat",
    sha256 = "f496774f56e8260e277dc17366cf670b55dee3616327a13d2d04bd1b62cdcc88",
    strip_prefix = "rules_swiftformat-0.4.1",
    urls = [
        "http://github.com/cgrindel/rules_swiftformat/archive/v0.4.1.tar.gz",
    ],
)

load("@cgrindel_rules_swiftformat//swiftformat:deps.bzl", "swiftformat_rules_dependencies")

swiftformat_rules_dependencies()

# Configure the dependencies for rules_swiftformat

load(
    "@cgrindel_bazel_starlib//:deps.bzl",
    "bazel_starlib_dependencies",
)

bazel_starlib_dependencies()

# We are using rules_spm to download and build SwiftFormat. The following will configure
# rules_spm to do that.

load("@cgrindel_rules_swiftformat//swiftformat:load_package.bzl", "swiftformat_load_package")

swiftformat_load_package()