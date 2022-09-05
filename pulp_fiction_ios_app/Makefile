BAZEL=bazel

build_app:
	${BAZEL} build :build_app --apple_platform_type=ios

build_protos:
	${BAZEL} build //protos:pulp_fiction_grpc_stubs_swift --apple_platform_type=ios

build_source:
	${BAZEL} build :build_source --apple_platform_type=ios

build_xcodeproj:
	${BAZEL} run  -- @tulsi//:tulsi -- --genconfig "${PWD}/PulpFictionApp.tulsiproj:build_and_test" --outputfolder="${PWD}"

clean:
	${BAZEL} clean

format:
	${BAZEL} build :format && ${BAZEL} run :format_update

test_all:
	${BAZEL} test ... --apple_platform_type=ios --test_output=all

test_unit:
	${BAZEL} test :test_unit --apple_platform_type=ios --test_output=all

tulsi:
	${BAZEL} run @tulsi//:tulsi
