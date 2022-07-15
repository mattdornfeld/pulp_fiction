load(
    "@com_github_grpc_grpc_kotlin//:kt_jvm_grpc.bzl",
    "kt_jvm_grpc_library",
    "kt_jvm_proto_library",
)

load(
    "@io_bazel_rules_kotlin//kotlin:jvm.bzl",
    "kt_jvm_binary",
    "kt_jvm_library",
    "kt_jvm_test",
)

load(
    "@io_bazel_rules_kotlin//kotlin:lint.bzl",
    "ktlint_fix",
    "ktlint_test",
)

load(
    "@rules_java//java:defs.bzl",
    "java_proto_library"
    )

MAIN_SRC_FILES = ["src/main/kotlin/**/*.kt"]
TEST_SRC_FILES = ["src/test/kotlin/**/*.kt"]
SRC_FILES = MAIN_SRC_FILES + TEST_SRC_FILES

kt_jvm_proto_library(
    name = "build_kotlin_protos",
    deps = ["//protos:pulp_fiction_proto"],
)

kt_jvm_grpc_library(
    name = "build_kotlin_grpc",
    srcs = ["//protos:pulp_fiction_proto"],
    deps = [":build_kotlin_protos"],
)

ktlint_fix(
    name = "lint_and_fix",
    srcs = glob(SRC_FILES),
)

kt_jvm_library(
    name = "pulp_fiction_backend_service_lib",
    srcs = glob(MAIN_SRC_FILES),
    deps = [
        ":build_kotlin_grpc",
        ":build_kotlin_protos",
        "@maven//:com_google_guava_guava",
        "@maven//:com_google_protobuf_protobuf_java",
        "@maven//:com_google_protobuf_protobuf_kotlin",
        "@maven//:com_password4j_password4j",
        "@maven//:io_arrow_kt_arrow_core_jvm",
        "@maven//:io_grpc_grpc_kotlin_stub",
        "@maven//:io_grpc_grpc_netty_shaded",
        "@maven//:io_grpc_grpc_protobuf",
        "@maven//:io_grpc_grpc_stub",
        "@maven//:org_flywaydb_flyway_core",
        "@maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@maven//:org_ktorm_ktorm_core",
        "@maven//:org_ktorm_ktorm_support_postgresql",
        "@maven//:org_postgresql_postgresql",
        "@maven//:software_amazon_awssdk_apache_client",
        "@maven//:software_amazon_awssdk_auth",
        "@maven//:software_amazon_awssdk_core",
        "@maven//:software_amazon_awssdk_http_client_spi",
        "@maven//:software_amazon_awssdk_regions",
        "@maven//:software_amazon_awssdk_s3",
    ],
    resources = glob(["src/main/resources/**/*"]),
)

kt_jvm_library(
    name = "pulp_fiction_backend_service_tests_lib",
    srcs = glob(TEST_SRC_FILES),
    deps = [
        ":pulp_fiction_backend_service_lib",
        "@maven//:com_adobe_testing_s3mock_junit5",
        "@maven//:com_adobe_testing_s3mock_testcontainers",
        "@maven//:io_arrow_kt_arrow_fx_coroutines_jvm",
        "@maven//:io_github_serpro69_kotlin_faker",
        "@maven//:org_jetbrains_kotlin_kotlin_test_junit5",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_junit_jupiter_junit_jupiter_api",
        "@maven//:org_junit_jupiter_junit_jupiter_engine",
        "@maven//:org_junit_platform_junit_platform_console",
        "@maven//:org_slf4j_slf4j_api",
        "@maven//:org_slf4j_slf4j_simple",
        "@maven//:org_testcontainers_junit_jupiter",
        "@maven//:org_testcontainers_postgresql",
        "@maven//:org_testcontainers_testcontainers",
    ],
)

kt_jvm_test(
    name = "co.firstorderlabs.pulpfiction.backendserver.PulpFictionBackendServiceTest",
    test_class = "co.firstorderlabs.pulpfiction.backendserver.PulpFictionBackendServiceTest",
    deps = [
        ":pulp_fiction_backend_service_tests_lib",
    ],
    visibility = ["//visibility:public"],
    main_class = "org.junit.platform.console.ConsoleLauncher",
    args = [
        "--select-package=co.firstorderlabs.pulpfiction.backendserver",
    ],
)

kt_jvm_test(
    name = "co.firstorderlabs.pulpfiction.backendserver.database.MigrateDatabaseTest",
    test_class = "co.firstorderlabs.pulpfiction.backendserver.database.MigrateDatabaseTest",
    deps = [
        ":pulp_fiction_backend_service_tests_lib",
    ],
    visibility = ["//visibility:public"],
    main_class = "org.junit.platform.console.ConsoleLauncher",
    args = [
        "--select-package=co.firstorderlabs.pulpfiction.backendserver.database",
    ],
)

kt_jvm_test(
    name = "co.firstorderlabs.pulpfiction.backendserver.S3MessengerTest",
    test_class = "co.firstorderlabs.pulpfiction.backendserver.S3MessengerTest",
    deps = [
        ":pulp_fiction_backend_service_tests_lib",
    ],
    visibility = ["//visibility:public"],
    main_class = "org.junit.platform.console.ConsoleLauncher",
    args = [
        "--select-package=co.firstorderlabs.pulpfiction.backendserver",
    ],
)

ktlint_test(
    name = "test_lint",
    srcs = glob(SRC_FILES),
    visibility = ["//visibility:public"],
)

kt_jvm_binary(
    name = "pulp_fiction_backend_service",
    main_class = "co.firstorderlabs.pulpfiction.PulpFictionBackendServerKt",
    srcs = glob(MAIN_SRC_FILES),
    deps = [
        ":pulp_fiction_backend_service_lib",
    ],
    visibility = ["//visibility:public"],
)
