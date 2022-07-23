load(
    "@rules_terraform//:defs.bzl",
    "terraform_format_test",
    "terraform_module",
    "terraform_root_module",
    "terraform_validate_test",
)

TERRAFORM = "@terraform_1_2_5//:terraform"

terraform_module(
    name = "module",
    srcs = glob(["**/*.tf"]),
    providers = [
        "@terraform_provider_local_2_1_0//:provider",
    ],
)

terraform_root_module(
    name = "root_module",
    module = ":module",
    terraform = TERRAFORM,
    visibility = ["//visibility:public"],
)

terraform_validate_test(
    name = "validate",
    root_module = ":root_module",
    visibility = ["//visibility:public"],
)

terraform_format_test(
    name = "format",
    module = ":module",
    terraform = TERRAFORM,
    visibility = ["//visibility:public"],
)
