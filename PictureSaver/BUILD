load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PictureSaverSource",
    srcs = glob([
        "PictureSaver/**/*.swift",
    ]),
    deps = [
        "@swift_pkgs//swift-log:Logging",
        "@swift_pkgs//SQLite.swift:SQLite",
    ],
)

ios_application(
    name = "PictureSaverApp",
    bundle_id = "com.example.PictureSaver",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "15.0",
    infoplists = [":PictureSaver/Info.plist"],
    visibility = ["//visibility:public"],
    deps = [":PictureSaverSource"],
)

platform(
    name = "myplatform",
    constraint_values = [
        "@platforms//cpu:arm",
    ],
)