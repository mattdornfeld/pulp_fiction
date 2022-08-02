load(
    "@rules_terraform//:defs.bzl",
    "terraform_format_test",
    "terraform_module",
    "terraform_root_module",
    "terraform_validate_test",
)

load(
    "//bazel:constants.bzl",
    "TERRAFORM",
    "TERRAFORM_AWS_PROVIDER"
)

SECRETS_FILES = [
    "//secrets:pulp_fiction_backend_service_database_credentials.yml.encrypted",
    ]

terraform_module(
    name = "module",
    srcs = glob(["**/*.tf"]) + SECRETS_FILES,
    providers = [
        TERRAFORM_AWS_PROVIDER,
    ],
    deps = [
        "//terraform/modules/pulp_fiction_aws_account:module",
        "//terraform/modules/pulp_fiction_aws_account/modules/pulp_fiction_ecr_repository:module",
    ]
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
