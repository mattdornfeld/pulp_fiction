load(
    "@cgrindel_rules_spm//spm:defs.bzl",
    "spm_pkg",
    "spm_repositories",
    )

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")

def _swift_library_template(swift_module_name, srcs, deps):
    return """
swift_library(
    name = "{swift_module_name}",
    srcs = glob({srcs}),
    deps = {deps},
    module_name = "{swift_module_name}",
    visibility = ["//visibility:public"],
)
""".format(swift_module_name=swift_module_name, srcs=srcs, deps=deps)

def _build_file_template(swift_module_map):
    swift_libraries = [
        _swift_library_template(swift_module_name, v["srcs"], v.get("deps", []))
        for swift_module_name, v in swift_module_map.items()
        ]
    load_rules = 'load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")'
    x = load_rules + "\n".join(swift_libraries)
#    print(x)
    return x

def new_git_swift_repository(name, remote, commit, swift_module_map):
    new_git_repository(
        name = name,
        remote = remote,
        commit = commit,
        build_file_content = _build_file_template(swift_module_map),
    )

def pulp_fiction_swift_dependencies():
    # Version 6.0.0
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

    # Version 0.4.1
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

    # Version 0.9.2
    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_case_paths",
        remote = "https://github.com/pointfreeco/swift-case-paths.git",
        commit = "7346701ea29da0a85d4403cf3d7a589a58ae3dee",
        swift_module_map = {
            "CasePaths" : {
                "srcs": ["Sources/CasePaths/**/*.swift"]
            }
        },
    )

    # Version 0.8.0
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

    # Version 0.5.2
    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_custom_dump",
        remote = "https://github.com/pointfreeco/swift-custom-dump.git",
        commit = "c9b6b940d95c0a925c63f6858943415714d8a981",
        swift_module_map = {
            "CustomDump" : {
                "srcs": ["Sources/CustomDump/**/*.swift"],
                "deps": ["@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay"],
            }
        },
    )

    # Version 1.0.3
    new_git_swift_repository(
        name = "com_github_apple_swift_collections2",
        remote = "https://github.com/apple/swift-collections",
        commit = "f504716c27d2e5d4144fa4794b12129301d17729",
        swift_module_map = {
            "DequeModule" : {
                "srcs": ["Sources/DequeModule/**/*.swift"],
            },
            "OrderedCollections" : {
                "srcs": ["Sources/OrderedCollections/**/*.swift"],
            },
            "Collections" : {
                "srcs": ["Sources/Collections/**/*.swift"],
                "deps": [
                    ":DequeModule",
                    ":OrderedCollections",
                ]
            },
        },
    )

    # Version 0.4.1
    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_identified_collections",
        remote = "https://github.com/pointfreeco/swift-identified-collections.git",
        commit = "bfb0d43e75a15b6dfac770bf33479e8393884a36",
        swift_module_map = {
            "IdentifiedCollections" : {
                "srcs": ["Sources/IdentifiedCollections/**/*.swift"],
                "deps": [
                    "@com_github_apple_swift_collections2//:OrderedCollections",
                ],
            }
        },
    )

    new_git_swift_repository(
        name = "com_github_apple_swift_async_algorithms",
        remote = "https://github.com/apple/swift-async-algorithms",
        commit = "cf70e78632e990cd041fef21044e54fa5fdd1c56",
        swift_module_map = {
            "AsyncAlgorithms" : {
                "srcs": ["Sources/AsyncAlgorithms/**/*.swift"],
                "deps": [
                    "@com_github_apple_swift_collections2//:Collections",
                ]
            }
        },
    )

    # Version 0.1.4
    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_clocks",
        remote = "https://github.com/pointfreeco/swift-clocks",
        commit = "5117092f7fa74656a3944870ef21c8c22ad1c09c",
        swift_module_map = {
            "Clocks" : {
                "srcs": ["Sources/Clocks/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay",
                    "@com_github_apple_swift_async_algorithms//:AsyncAlgorithms"
                ],
            }
        },
    )

    # Version 0.1.4
    new_git_swift_repository(
        name = "com_github_pointfreeco_swiftui_navigation",
        remote = "https://github.com/pointfreeco/swiftui-navigation",
        commit = "4ab0f87a77d4e1b537fece1f1272b3edc5ce9eed",
        swift_module_map = {
            "_SwiftUINavigationState" : {
                "srcs": ["Sources/_SwiftUINavigationState/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_swift_case_paths//:CasePaths",
                    "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
                ],
            }
        },
    )

    # Version 0.47.2
    new_git_swift_repository(
        name = "com_github_pointfreeco_swift_composable_architecture",
        remote = "https://github.com/pointfreeco/swift-composable-architecture.git",
        commit = "c9259b5f74892690cb04a9a8088b4a1789b05a7d",
        swift_module_map = {
            "ComposableArchitecture" : {
                "srcs": ["Sources/ComposableArchitecture/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_combine_schedulers//:CombineSchedulers",
                    "@com_github_pointfreeco_swift_case_paths//:CasePaths",
                    "@com_github_pointfreeco_swift_composable_architecture//:Dependencies",
                    "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
                    "@com_github_pointfreeco_swift_identified_collections//:IdentifiedCollections",
                    "@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay",
                    "@com_github_pointfreeco_swift_clocks//:Clocks",
                    "@com_github_pointfreeco_swiftui_navigation//:_SwiftUINavigationState",
                ],
            },
            "Dependencies" : {
                "srcs": ["Sources/Dependencies/**/*.swift"],
                "deps": [
                    "@com_github_pointfreeco_combine_schedulers//:CombineSchedulers",
                    "@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay",
                    "@com_github_pointfreeco_swift_clocks//:Clocks"
                ],
            }
        },
    )

    # Version 0.8.0
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

def pulp_fiction_swift_spm_dependencies():
    spm_repositories(
        name = "swift_pkgs",
        platforms = [
            ".macOS(.v10_15)",
        ],
        dependencies = [
            spm_pkg(
                url = "https://github.com/apple/swift-log.git",
                exact_version = "1.4.2",
                products = ["Logging"],
            ),
            spm_pkg(
                url = "https://github.com/pointfreeco/swift-composable-architecture.git",
                exact_version = "0.43.0",
                products = ["ComposableArchitecture"],
            ),
            spm_pkg(
                name = "Bow",
                url = "https://github.com/bow-swift/bow.git",
                exact_version = "0.8.0",
                products = ["Bow", "BowEffects", "BowOptics"],
            ),
            spm_pkg(
                url = "https://github.com/grpc/grpc-swift.git",
                exact_version = "1.7.3",
                products = ["GRPC"],
            ),
            spm_pkg(
                url = "https://github.com/hyperoslo/Cache",
                exact_version = "6.0.0",
                products = ["Cache"],
            ),
        ],
    )
