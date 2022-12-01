BAZEL=bazel

config = ios_simulator

build_app:
	${BAZEL} build :build_app --config=$(config)

build_preview_app:
	${BAZEL} build :build_preview_app --config=$(config)

build_protos:
	${BAZEL} build //protos:pulp_fiction_grpc_stubs_swift

build_source:
	${BAZEL} build :build_app_source --config=$(config)

build_xcodeproj:
	${BAZEL} run :build_xcodeproj

clean:
	${BAZEL} clean

format:
	${BAZEL} build :format && ${BAZEL} run :format_update

run_preview_app:
	${BAZEL} run :build_preview_app --config=$(config)

test_all:
	${BAZEL} test ... --config=ios --test_output=all

test_unit:
	${BAZEL} test :test_unit --config=ios --test_output=all
