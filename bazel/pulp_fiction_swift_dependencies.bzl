load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")

def _swift_library_template(swift_module_name, srcs, deps):
    return """
swift_library(
    name = "{}",
    srcs = glob({}),
    deps = {},
    visibility = ["//visibility:public"],
)
""".format(swift_module_name, srcs, deps)

def _build_file_template(swift_module_map):
    swift_libraries = [
        _swift_library_template(swift_module_name, v["srcs"], v.get("deps", []))
        for swift_module_name, v in swift_module_map.items()
        ]
    load_rules = 'load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")'
    return load_rules + "\n".join(swift_libraries)

def new_git_swift_repository(name, remote, commit, swift_module_map):
    new_git_repository(
        name = name,
        remote = remote,
        commit = commit,
        build_file_content = _build_file_template(swift_module_map),
    )

def pulp_fiction_swift_dependencies():
    new_git_swift_repository(
        name = "com_github_hyperoslo_cache",
        remote = "https://github.com/hyperoslo/Cache.git",
        commit = "c7f4d633049c3bd649a353bad36f6c17e9df085f",
        swift_module_map = {
            "Cache": {
                "srcs": ["Source/**/*.swift"],
            }
        }
    )

    new_git_repository(
        name = "com_github_bow_swift_bow",
        remote = "https://github.com/bow-swift/bow.git",
        commit = "17ff76f1e0427a67e221c0a20b96324d256c340f",
        build_file = "@//:third_party/bow_swift/bow/BUILD",
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_xctest_dynamic_overlay",
        remote = "https://github.com/pointfreeco/xctest-dynamic-overlay",
        commit = "30314f1ece684dd60679d598a9b89107557b67d9",
        swift_module_map = {
            "XCTestDynamicOverlay" : {
                "srcs": ["Sources/XCTestDynamicOverlay/**/*.swift"]
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_case_paths",
        remote = "https://github.com/pointfreeco/swift-case-paths.git",
        commit = "241301b67d8551c26d8f09bd2c0e52cc49f18007",
        swift_module_map = {
            "CasePaths" : {
                "srcs": ["Sources/CasePaths/**/*.swift"]
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_combine_schedulers",
        remote = "https://github.com/pointfreeco/combine-schedulers.git",
        commit = "aa3e575929f2bcc5bad012bd2575eae716cbcdf7",
        swift_module_map = {
            "CombineSchedulers" : {
                "srcs": ["Sources/CombineSchedulers/**/*.swift"],
                "deps": ["@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay"],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_custom_dump",
        remote = "https://github.com/pointfreeco/swift-custom-dump.git",
        commit = "51698ece74ecf31959d3fa81733f0a5363ef1b4e",
        swift_module_map = {
            "CustomDump" : {
                "srcs": ["Sources/CustomDump/**/*.swift"],
                "deps": ["@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay"],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_apple_swift_collections",
        remote = "https://github.com/apple/swift-collections",
        commit = "48254824bb4248676bf7ce56014ff57b142b77eb",
        swift_module_map = {
            "OrderedCollections" : {
                "srcs": ["Sources/OrderedCollections/**/*.swift"],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_identified_collections",
        remote = "https://github.com/pointfreeco/swift-identified-collections.git",
        commit = "680bf440178a78a627b1c2c64c0855f6523ad5b9",
        swift_module_map = {
            "IdentifiedCollections" : {
                "srcs": ["Sources/IdentifiedCollections/**/*.swift"],
                "deps": [
                    "@com_github_apple_swift_collections//:OrderedCollections",
                ],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_composable_architecture",
        remote = "https://github.com/pointfreeco/swift-composable-architecture.git",
        commit = "5bd450a8ac6a802f82d485bac219cbfacffa69fb",
        swift_module_map = {
            "ComposableArchitecture" : {
                "srcs": ["Sources/ComposableArchitecture/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_swift_case_paths//:CasePaths",
                    "@com_github_pointfreeco_combine_schedulers//:CombineSchedulers",
                    "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
                    "@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay",
                    "@com_github_pointfreeco_swift_composable_architecture//:Dependencies",
                    "@com_github_pointfreeco_swift_identified_collections//:IdentifiedCollections",
                ],
            },
            "Dependencies" : {
                "srcs": ["Sources/Dependencies/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_combine_schedulers//:CombineSchedulers",
                    "@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay",
                ],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_bow_swift_bow",
        remote = "https://github.com/bow-swift/bow.git",
        commit = "17ff76f1e0427a67e221c0a20b96324d256c340f",
        swift_module_map = {
            "Bow" : {
                "srcs": ["Sources/Bow/**/*.swift"],
            },
            "BowEffects" : {
                "srcs": ["Sources/BowEffects/**/*.swift"],
                "deps": [":Bow"],
            },
            "BowOptics" : {
                "srcs": ["Sources/BowOptics/**/*.swift"],
                "deps": [":Bow"],
            },
        },
    )
