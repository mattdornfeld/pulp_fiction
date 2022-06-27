BAZEL=bazel

build_protos:
	${BAZEL} build :build_kotlin_grpc

build_jar:
	${BAZEL} build :pulp_fiction_backend_service

configure_dev:
	chmod u+x sbin/configure.sh && sbin/configure.sh

lint_and_fix:
	${BAZEL} run :lint_and_fix

run_locally:
	${BAZEL} run :pulp_fiction_backend_service

test_all:
	${BAZEL} test ...

test_unit:
	${BAZEL} test :pulp_fiction_backend_service_tests

test_lint:
	${BAZEL} test :test_lint