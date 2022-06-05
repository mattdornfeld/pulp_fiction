BAZEL=bazel

build_app:
	${BAZEL} build :build_app --apple_platform_type=ios

build_protos:
	${BAZEL} build :build_swift_protos --apple_platform_type=ios

build_source:
	${BAZEL} build :build_source --apple_platform_type=ios

format:
	${BAZEL} build :format && ${BAZEL} run :format_update
