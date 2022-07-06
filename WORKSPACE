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

ARROW_VERSION = "1.1.2"
AWS_SDK_VERSION = "1.11.729"
FLOGGER_VERSION = '0.7.4'
GRPC_VERSION = "1.47.0"
JUNIT_VERSION = "5.8.2"
KOTLIN_VERSION = "1.6.0"
KTORM_VERSION = "3.5.0"
PROTOBUF_VERSION = "3.18.0"
S3_MOCK_VERSION = "2.4.13"
TEST_CONTAINERS_VERSION = "1.17.2"

maven_install(
    name = "maven",
    artifacts = [
        "com.adobe.testing:s3mock-docker:" + S3_MOCK_VERSION,
        "com.adobe.testing:s3mock-junit5:" + S3_MOCK_VERSION,
        "com.adobe.testing:s3mock-testcontainers:" + S3_MOCK_VERSION,
        "com.amazonaws:aws-java-sdk-core:" + AWS_SDK_VERSION,
        "com.amazonaws:aws-java-sdk-s3:" + AWS_SDK_VERSION,
        "com.google.guava:guava:31.1-jre",
        "com.google.protobuf:protobuf-java:" + PROTOBUF_VERSION,
        "com.google.protobuf:protobuf-kotlin:" + PROTOBUF_VERSION,
        "com.squareup:kotlinpoet:1.11.0",
        "io.arrow-kt:arrow-core-jvm:" + ARROW_VERSION,
        "io.arrow-kt:arrow-fx-coroutines-jvm:" + ARROW_VERSION,
        "io.github.serpro69:kotlin-faker:1.11.0",
        "io.grpc:grpc-kotlin-stub:1.3.0",
        "io.grpc:grpc-netty-shaded:" + GRPC_VERSION,
        "io.grpc:grpc-protobuf:" + GRPC_VERSION,
        "io.grpc:grpc-stub:" + GRPC_VERSION,
        "org.flywaydb:flyway-core:8.5.13",
        "org.jetbrains.kotlin:kotlin-test-junit5:" + KOTLIN_VERSION,
        "org.jetbrains.kotlin:kotlin-test:" + KOTLIN_VERSION,
        "org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:" + KOTLIN_VERSION,
        "org.jetbrains.kotlinx:kotlinx-coroutines-core:" + KOTLIN_VERSION,
        "org.junit.jupiter:junit-jupiter-api:" + JUNIT_VERSION,
        "org.junit.jupiter:junit-jupiter-engine:" + JUNIT_VERSION,
        "org.junit.jupiter:junit-jupiter:" + JUNIT_VERSION,
        "org.junit.platform:junit-platform-console:1.8.2",
        "org.ktorm:ktorm-core:" + KTORM_VERSION,
        "org.ktorm:ktorm-support-postgresql:" + KTORM_VERSION,
        "org.postgresql:postgresql:42.2.24",
        "org.slf4j:slf4j-api:1.7.36",
        "org.slf4j:slf4j-simple:1.7.36",
        "org.testcontainers:junit-jupiter:" + TEST_CONTAINERS_VERSION,
        "org.testcontainers:postgresql:" + TEST_CONTAINERS_VERSION,
        "org.testcontainers:testcontainers:" + TEST_CONTAINERS_VERSION,
        "software.amazon.awssdk:apache-client:2.17.224",
        "software.amazon.awssdk:core:2.17.224",
        "software.amazon.awssdk:s3:2.17.224",
#        "com.google.flogger:flogger-slf4j-backend:" + FLOGGER_VERSION,
#        "com.google.flogger:flogger:" + FLOGGER_VERSION,
    ] + IO_GRPC_GRPC_JAVA_ARTIFACTS,
    generate_compat_repositories = True,
    repositories = [
#        "https://oss.sonatype.org/content/repositories/snapshots/",
        "https://repo1.maven.org/maven2",
    ],
    version_conflict_policy = "pinned",
)

load(
    "@maven//:compat.bzl",
    "compat_repositories",
    )
compat_repositories()

