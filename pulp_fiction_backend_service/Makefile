BAZEL=bazel

build_protos:
	${BAZEL} build :build_kotlin_grpc

build_jar:
	${BAZEL} build :pulp_fiction_backend_service

run_locally:
	${BAZEL} run :pulp_fiction_backend_service

test_unit:
	${BAZEL} test :pulp_fiction_backend_service_tests