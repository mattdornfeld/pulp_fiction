BAZEL=bazel

build_all:
	$(BAZEL) build ... --apple_platform_type=ios

test_all:
	$(BAZEL) test ... --apple_platform_type=ios --test_output=all
