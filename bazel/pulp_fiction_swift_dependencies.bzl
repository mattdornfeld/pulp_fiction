load(
    "@cgrindel_rules_spm//spm:defs.bzl",
    "spm_pkg",
    "spm_repositories",
    )

def pulp_fiction_swift_dependencies():
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
                url = "https://github.com/stephencelis/SQLite.swift.git",
                exact_version = "0.13.3",
                products = ["SQLite"],
            ),
            spm_pkg(
                url = "https://github.com/pointfreeco/swift-composable-architecture.git",
                exact_version = "0.39.1",
                products = ["ComposableArchitecture"],
            ),
            spm_pkg(
                name = "Bow",
                url = "https://github.com/bow-swift/bow.git",
                exact_version = "0.8.0",
                products = ["Bow", "BowEffects"],
            ),
            spm_pkg(
                url = "https://github.com/grpc/grpc-swift.git",
                exact_version = "1.7.3",
                products = ["GRPC"],
            ),
        ],
    )

#    http_archive(
#        name = "com_github_grpc_grpc_swift",
#        urls = ["https://github.com/grpc/grpc-swift/archive/1.7.3.tar.gz"],
#        sha256 = "833a150bdebb8ec0282fd91761aec0705a9b05645de42619b60fb6b9ec04b786",
#        strip_prefix = "grpc-swift-1.7.3/",
#        build_file = "@build_bazel_rules_swift//third_party:com_github_grpc_grpc_swift/BUILD.overlay",
#    )
