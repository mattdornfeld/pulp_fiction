load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_proto_library")
load("@cgrindel_rules_swiftformat//swiftformat:defs.bzl", "swiftformat_pkg", "swiftformat_library", "swiftformat_format", "swiftformat_test")

platform(
    name = "myplatform",
    constraint_values = [
        "@platforms//cpu:arm",
    ],
)

swift_proto_library(
    name = "build_swift_protos",
    deps = ["//protos:pulp_fiction_proto"],
)

swift_library(
    name = "build_source",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
    ]),
    deps = [
        "@swift_pkgs//swift-log:Logging",
        "@swift_pkgs//SQLite.swift:SQLite",
        "@swift_pkgs//swift-composable-architecture:ComposableArchitecture",
        ":build_swift_protos"
    ],
    module_name = "PulpFictionApp"
)

swift_library(
    name = "build_tests",
    srcs = glob([
        "PulpFictionTests/**/*.swift",
    ]),
    deps = [
        ":build_source"
    ],
)

ios_unit_test(
    name = "test_unit",
    data = glob([
        "PulpFictionTests/**/*.swift",
    ]),
    deps = [
        ":build_tests"
    ],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
)

ios_application(
    name = "build_app",
    bundle_name = "pulp_fiction",
    bundle_id = "co.firstorderlabs.PulpFictionApp",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "15.0",
    infoplists = [":PulpFictionApp/Info.plist"],
    visibility = ["//visibility:public"],
    deps = [":build_source"],
)

swiftformat_format(
    name = "format",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
        "PulpFictionTests/**/*.swift",
    ]),
)

swiftformat_pkg(
    name = "format",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
        "PulpFictionTests/**/*.swift",
    ]),
)
