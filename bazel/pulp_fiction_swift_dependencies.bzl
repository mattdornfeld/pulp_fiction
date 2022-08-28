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
                products = ["Bow"],
            ),
        ],
    )
