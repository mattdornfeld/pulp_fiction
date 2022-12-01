load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@cgrindel_rules_swiftformat//swiftformat:defs.bzl", "swiftformat_pkg", "swiftformat_library", "swiftformat_format", "swiftformat_test")
load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")

platform(
    name = "myplatform",
    constraint_values = [
        "@platforms//cpu:arm",
    ],
)

swift_library(
    name = "build_app_source",
    srcs = glob([
        "PulpFictionAppSource/**/*.swift",
    ]),
    deps = [
        "//protos:pulp_fiction_grpc_stubs_swift",
        "//protos:pulp_fiction_grpc_swift",
        "@com_github_hyperoslo_cache//:Cache",
        "@com_github_pointfreeco_swift_composable_architecture//:ComposableArchitecture",
        "@com_github_bow_swift_bow//:Bow",
        "@com_github_bow_swift_bow//:BowEffects",
        "@com_github_bow_swift_bow//:BowOptics",
    ],
    module_name = "PulpFictionAppSource"
)

swift_library(
    name = "build_app_executable_source",
    srcs = glob([
        "PulpFictionApp/**/*.swift",
    ]),
    deps = [
        ":build_app_source"
    ],
    module_name = "PulpFictionApp"
)

swift_library(
    name = "build_app_preview_source",
    srcs = glob([
        "PulpFictionAppPreview/**/*.swift",
    ]),
    data = glob([
        "PulpFictionAppPreview/Assets.xcassets/**/*",
    ]),
    deps = [
        ":build_app_source",
    ],
    module_name = "PulpFictionAppPreview",
)

swift_library(
    name = "build_tests",
    srcs = glob([
        "PulpFictionTests/**/*.swift",
    ]),
    data = glob([
        "PulpFictionAppPreview/Assets.xcassets/**/*",
    ]),
    deps = [
        ":build_app_preview_source",
    ],
    module_name = "PulpFictionTests",
)

ios_application(
    name = "build_app",
    bundle_name = "PulpFictionApp",
    bundle_id = "co.firstorderlabs.PulpFictionApp",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "15.0",
    infoplists = [":PulpFictionApp/Info.plist"],
    visibility = ["//visibility:public"],
    deps = [
        ":build_app_executable_source",
    ],
    provisioning_profile = "PulpFictionApp.mobileprovision",
)

filegroup(
    name = "preview_app_assets",
    srcs = glob([
        "PulpFictionAppPreview/Assets.xcassets/**/*",
    ]),
)

ios_application(
    name = "build_preview_app",
    bundle_name = "PulpFictionAppPreview",
    bundle_id = "co.firstorderlabs.PulpFictionAppPreview",
    families = [
        "iphone",
        "ipad",
    ],
    resources = [":preview_app_assets"],
    minimum_os_version = "15.0",
    infoplists = [":PulpFictionApp/Info.plist"],
    visibility = ["//visibility:public"],
    deps = [
        ":build_app_preview_source",
    ],
    provisioning_profile = "PulpFictionApp.mobileprovision",
)

ios_unit_test(
    name = "test_unit",
    bundle_id = "co.firstorderlabs.PulpFictionTests",
    data = glob([
        "PulpFictionTests/**/*.swift",
    ]),
    deps = [
        ":build_tests",
    ],
    env = {
        "resourceBundleFileIdentifier": "co.firstorderlabs.PulpFictionTests",
    },
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
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
        "PulpFictionAppPreview/**/*.swift",
        "PulpFictionAppSource/**/*.swift",
        "PulpFictionTests/**/*.swift",
    ]),
)

xcodeproj(
    name = "build_xcodeproj",
    project_name = "PulpFictionApp",
    tags = ["manual"],
    top_level_targets = [
        ":build_app",
        ":build_preview_app",
        ":test_unit",
    ],
    build_mode = "xcode",
)
