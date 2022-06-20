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
        "@maven//:com_google_protobuf_protobuf_kotlin",
        "@maven//:com_google_protobuf_protobuf_java",
        "@maven//:io_grpc_grpc_kotlin_stub",
        "@maven//:io_grpc_grpc_netty_shaded",
        "@maven//:io_grpc_grpc_protobuf",
        "@maven//:io_grpc_grpc_stub",
        "@maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
    ],
)

kt_jvm_library(
    name = "pulp_fiction_backend_service_tests_lib",
    srcs = glob(TEST_SRC_FILES),
    deps = [
        ":pulp_fiction_backend_service_lib",
        "@maven//:org_jetbrains_kotlin_kotlin_test",
        "@maven//:org_jetbrains_kotlin_kotlin_test_junit5",
        "@maven//:junit_junit",
        "@maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core_jvm",
    ],
)

kt_jvm_test(
    name = "pulp_fiction_backend_service_tests",
    test_class = "co.firstorderlabs.pulpfiction.PulpFictionBackendServerTest",
    deps = [
        ":pulp_fiction_backend_service_tests_lib",
    ],
    visibility = ["//visibility:public"],
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
