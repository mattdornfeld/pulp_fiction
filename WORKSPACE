workspace(name = "pulp_fiction")

load(
    ":repositories.bzl",
    "pulp_fiction_dependencies",
    )
pulp_fiction_dependencies()

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
    "@cgrindel_rules_spm//spm:deps.bzl",
    "spm_rules_dependencies",
)
spm_rules_dependencies()

load(
    "@rules_proto//proto:repositories.bzl",
    "rules_proto_dependencies",
    "rules_proto_toolchains",
    )
rules_proto_dependencies()
rules_proto_toolchains()

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

load(
    "@cgrindel_rules_spm//spm:defs.bzl",
    "spm_pkg",
    "spm_repositories",
    )
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
    "@io_grpc_grpc_java//:repositories.bzl",
    "IO_GRPC_GRPC_JAVA_ARTIFACTS"
    )

maven_install(
    name = "maven",
    artifacts = [
        "com.google.protobuf:protobuf-kotlin:3.18.0",
    ] + IO_GRPC_GRPC_KOTLIN_ARTIFACTS + IO_GRPC_GRPC_JAVA_ARTIFACTS,
    generate_compat_repositories = True,
    repositories = [
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
)

load(
    "@maven//:compat.bzl",
    "compat_repositories",
    )
compat_repositories()

