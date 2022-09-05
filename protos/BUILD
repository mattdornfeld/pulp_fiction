load("@rules_proto//proto:defs.bzl", "proto_library")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_grpc_library", "swift_proto_library")

proto_library(
    name = "pulp_fiction_proto",
    srcs = ["pulp_fiction.proto"],
    visibility = ["//visibility:public"],
    deps = [
        "@com_google_protobuf//:timestamp_proto",
    ],
)

proto_library(
    name = "health_proto",
    srcs = ["health.proto"],
    visibility = ["//visibility:public"],
)

swift_proto_library(
    name = "pulp_fiction_protos_swift",
    deps = [":pulp_fiction_proto"],
    visibility = ["//visibility:public"],
)

swift_grpc_library(
    name = "pulp_fiction_grpc_swift",
    srcs = [":pulp_fiction_proto"],
    flavor = "client",
    deps = [":pulp_fiction_protos_swift"],
    visibility = ["//visibility:public"],
)

swift_grpc_library(
    name = "pulp_fiction_grpc_stubs_swift",
    srcs = [":pulp_fiction_proto"],
    flavor = "client_stubs",
    deps = [":pulp_fiction_grpc_swift"],
    visibility = ["//visibility:public"],
)
