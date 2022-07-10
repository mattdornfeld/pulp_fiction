load(
    "@io_bazel_rules_kotlin//kotlin:jvm.bzl",
    "kt_jvm_test",
)

def junit5_test(test_class, deps):
    select_package = ".".join(test_class.split(".")[:-1])
    kt_jvm_test(
        name = test_class,
        test_class = test_class,
        deps = deps,
        visibility = ["//visibility:public"],
        main_class = "org.junit.platform.console.ConsoleLauncher",
        args = [
            "--include-classname=" + test_class,
            "--select-package=" + select_package,
        ],
    )

def junit5_tests(test_classes, deps):
    for test_class in test_classes:
        junit5_test(test_class, deps)
