load(
    "@rules_terraform//:defs.bzl",
    "terraform_format_test",
    "terraform_module",
)

load(
    "//bazel:constants.bzl",
    "TERRAFORM",
    "TERRAFORM_AWS_PROVIDER"
)

terraform_module(
    name = "module",
    srcs = glob(["**/*.tf"]),
    providers = [
        TERRAFORM_AWS_PROVIDER,
    ],
    visibility = ["//visibility:public"],
)

terraform_format_test(
    name = "format",
    module = ":module",
    terraform = TERRAFORM,
)
