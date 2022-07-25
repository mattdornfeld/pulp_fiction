BAZEL=bazel

build_protos:
	${BAZEL} build :build_kotlin_grpc

build_jar:
	${BAZEL} build :pulp_fiction_backend_service

configure_dev:
	chmod u+x sbin/configure.sh && sbin/configure.sh

format:
	${BAZEL} run :format

run_locally:
	${BAZEL} run :pulp_fiction_backend_service

test_all:
	${BAZEL} test ...

#test_unit:
#	${BAZEL} test :co.firstorderlabs.pulpfiction.backendserver.PulpFictionBackendServiceTest

test_lint:
	${BAZEL} test :test_lint