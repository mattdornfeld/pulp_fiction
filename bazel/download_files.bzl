load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def download_files():
    http_file(
      name = "bazelisk_linux_amd64",
      urls = ["https://github.com/bazelbuild/bazelisk/releases/download/v1.12.0/bazelisk-linux-amd64"],
      sha256 = "6b0bcb2ea15bca16fffabe6fda75803440375354c085480fe361d2cbf32501db",
      executable = True,
      downloaded_file_path = "bazel",
    )
