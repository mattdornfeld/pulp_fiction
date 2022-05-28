load(
    "@cgrindel_bazel_starlib//updatesrc:defs.bzl",
    "updatesrc_update_all",
)

# We export this file to make it available to other Bazel packages in the workspace.
exports_files([".swiftformat"])

# Define a runnable target to copy all of the formatted files to the workspace directory.
updatesrc_update_all(
    name = "update_all",
)
