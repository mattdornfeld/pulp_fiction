workspace(name = "pulp_fiction")

load(
    "//bazel:repositories.bzl",
    "pulp_fiction_dependencies",
    )
pulp_fiction_dependencies()

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)
container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load(
    "@cgrindel_rules_spm//spm:deps.bzl",
    "spm_rules_dependencies",
)
spm_rules_dependencies()

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)
xcodeproj_rules_dependencies()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)
apple_rules_dependencies()

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

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)
apple_support_dependencies()

# The build breaks if the rules_proto http_archive is put into repositories.bzl so it's included here
load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive"
)
http_archive(
    name = "rules_proto",
    sha256 = "66bfdf8782796239d3875d37e7de19b1d94301e8972b3cbd2446b332429b4df1",
    strip_prefix = "rules_proto-4.0.0",
    url = "https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0.tar.gz",
)

load(
    "@rules_proto//proto:repositories.bzl",
    "rules_proto_dependencies",
    "rules_proto_toolchains",
    )
rules_proto_dependencies()
rules_proto_toolchains()

load(
    "//bazel:pulp_fiction_swift_dependencies.bzl",
    "pulp_fiction_swift_dependencies",
    "pulp_fiction_swift_spm_dependencies"
)
pulp_fiction_swift_dependencies()
pulp_fiction_swift_spm_dependencies()

load(
    "@cgrindel_rules_swiftformat//swiftformat:deps.bzl",
    "swiftformat_rules_dependencies"
    )
swiftformat_rules_dependencies()

load(
    "@cgrindel_bazel_starlib//:deps.bzl",
    "bazel_starlib_dependencies",
)
bazel_starlib_dependencies()

load(
    "@cgrindel_rules_swiftformat//swiftformat:load_package.bzl",
    "swiftformat_load_package",
    )
swiftformat_load_package()

load(
    "@rules_jvm_external//:repositories.bzl",
    "rules_jvm_external_deps",
    )
rules_jvm_external_deps()

load(
    "@rules_jvm_external//:setup.bzl",
    "rules_jvm_external_setup",
    )
rules_jvm_external_setup()

load(
    "@rules_jvm_external//:defs.bzl",
    "maven_install",
    )

load(
    "@io_bazel_rules_kotlin//kotlin:repositories.bzl",
    "kotlin_repositories"
    )
kotlin_repositories()

load(
    "@io_bazel_rules_kotlin//kotlin:core.bzl",
    "kt_register_toolchains"
    )
kt_register_toolchains()

load(
    "@com_github_grpc_grpc_kotlin//:repositories.bzl",
    "grpc_kt_repositories",
    "IO_GRPC_GRPC_KOTLIN_ARTIFACTS"
    )
grpc_kt_repositories()

load(
    "//bazel:pulp_fiction_maven_dependencies.bzl",
    "PULP_FICTION_MAVEN_DEPENDENCIES",
    )

load(
    "@io_grpc_grpc_java//:repositories.bzl",
    "IO_GRPC_GRPC_JAVA_ARTIFACTS"
    )

maven_install(
    name = "maven",
    artifacts = PULP_FICTION_MAVEN_DEPENDENCIES,
    generate_compat_repositories = True,
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
    version_conflict_policy = "pinned",
)

load(
    "@maven//:compat.bzl",
    "compat_repositories",
    )
compat_repositories()

load(
    "//bazel:pull_containers.bzl",
    "pull_containers",
    )
pull_containers()

load(
    "//bazel:download_files.bzl",
    "download_files",
    )
download_files()

load(
    "@rules_terraform//:deps.bzl",
    "rules_terraform_repositories",
    )
rules_terraform_repositories()

load(
    "@rules_terraform//:defs.bzl",
    "download_terraform_versions",
    "download_terraform_provider_versions",
    )

download_terraform_versions({
    # These are SHAs of the SHA265SUM file for a given version. They can be
    # found with:
    # curl https://releases.hashicorp.com/terraform/${version}/terraform_${version}_SHA256SUMS | sha256sum
    "1.2.5": "92995a096b55c013a2f2c388b5bb5eb30d805fa0710cf9d501696a271a819fba",
})

# Provider SHAs are from the SHA265SUM file for a given version. They can be
# found with:
# curl https://releases.hashicorp.com/terraform-provider-${name}/${version}/terraform-provider-${name}_${version}_SHA256SUMS | sha256sum
download_terraform_provider_versions(
    "aws",
    "registry.terraform.io/hashicorp/aws",
    {
        "4.23.0": "727bf2a345fcd5bebc9bde3f6f71d0c2ac46c207bc0236098b591042cb8a0790",
    },
)

download_terraform_provider_versions(
    "local",
    "registry.terraform.io/hashicorp/local",
    {
        "2.1.0": "dae594d82be6be5ee83f8d081cc8a05af45ac1bbf7fdb8bea16ab4c1d6032043",
    },
)

load(
    "@io_bazel_rules_go//go:deps.bzl",
    "go_register_toolchains",
    "go_rules_dependencies",
    )
go_rules_dependencies()

load(
    "@bazel_gazelle//:deps.bzl",
    "gazelle_dependencies",
    "go_repository",
    )
gazelle_dependencies()
