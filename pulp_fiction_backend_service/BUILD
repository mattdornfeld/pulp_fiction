load(
    "@com_github_grpc_grpc_kotlin//:kt_jvm_grpc.bzl",
    "kt_jvm_grpc_library",
    "kt_jvm_proto_library"
    )

kt_jvm_proto_library(
    name = "build_kotlin_protos",
    deps = ["//protos:pulp_fiction_proto"],
)

kt_jvm_grpc_library(
    name = "build_kotlin_grpc",
    srcs = ["//protos:pulp_fiction_proto"],
    deps = [":build_kotlin_protos"],
)
