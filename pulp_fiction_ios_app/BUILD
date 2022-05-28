load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_proto_library")
load("@cgrindel_rules_swiftformat//swiftformat:defs.bzl", "swiftformat_pkg", "swiftformat_library", "swiftformat_format")

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
        ":build_swift_protos"
    ],
)

ios_application(
    name = "build_app",
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

platform(
    name = "myplatform",
    constraint_values = [
        "@platforms//cpu:arm",
    ],
)

swiftformat_format(
    name = "format",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
    ]),
)

swiftformat_pkg(
    name = "format",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
    ]),
)