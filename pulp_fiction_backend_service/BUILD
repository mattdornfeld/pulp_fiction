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

load(
    "//bazel:junit5_test.bzl",
    "junit5_tests",
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
    name = "format",
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
        "@maven//:io_arrow_kt_arrow_core_jvm",
        "@maven//:io_grpc_grpc_kotlin_stub",
        "@maven//:io_grpc_grpc_netty_shaded",
        "@maven//:io_grpc_grpc_protobuf",
        "@maven//:io_grpc_grpc_stub",
        "@maven//:io_prometheus_simpleclient",
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
#        "@maven//:com_google_flogger_flogger_slf4j_backend",
#        "@maven//:com_google_flogger_flogger",
#        "@maven//:org_slf4j_slf4j_api",
#        "@maven//:org_slf4j_slf4j_simple",
    ],
    resources = glob(["src/main/resources/**/*"]),
)

kt_jvm_library(
    name = "pulp_fiction_backend_service_tests_lib",
    srcs = glob(TEST_SRC_FILES),
    deps = [
        ":pulp_fiction_backend_service_lib",
        "@maven//:com_amazonaws_aws_java_sdk_s3",
        "@maven//:io_arrow_kt_arrow_fx_coroutines_jvm",
        "@maven//:io_github_serpro69_kotlin_faker",
        "@maven//:org_jetbrains_kotlin_kotlin_test_junit5",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_junit_jupiter_junit_jupiter_api",
        "@maven//:org_junit_jupiter_junit_jupiter_engine",
        "@maven//:org_junit_platform_junit_platform_console",
        "@maven//:org_testcontainers_junit_jupiter",
        "@maven//:org_testcontainers_postgresql",
        "@maven//:org_testcontainers_testcontainers",
        "@maven//:org_testcontainers_localstack",
    ],
)

junit5_tests(
    deps = [":pulp_fiction_backend_service_tests_lib"],
    test_classes=[
        "co.firstorderlabs.pulpfiction.backendserver.PulpFictionBackendServiceTest",
        "co.firstorderlabs.pulpfiction.backendserver.MigrateDatabaseTest",
        "co.firstorderlabs.pulpfiction.backendserver.S3MessengerTest",
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
