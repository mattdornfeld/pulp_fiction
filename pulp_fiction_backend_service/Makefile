BAZEL=bazel

DOCKER_IMAGE_TAG := $(T)

build_image:
	$(BAZEL) run //docker_images/pulp_fiction_backend_service:build_image

build_and_push_image:
	$(BAZEL) run --define=DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_TAG) //docker_images/pulp_fiction_backend_service:push_image

build_protos:
	${BAZEL} build :build_kotlin_grpc_pulp_fiction_service :build_kotlin_grpc_health_service

build_jar:
	${BAZEL} build :pulp_fiction_backend_service_deploy.jar

deploy:
	${BAZEL} run --define=DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_TAG) :update_ecs_pulp_fiction_backend_service

configure_dev:
	chmod u+x sbin/configure.sh && sbin/configure.sh

format:
	${BAZEL} run :format

run_locally:
	${BAZEL} run :pulp_fiction_backend_service

test_all:
	${BAZEL} test ...

test_lint:
	${BAZEL} test :test_lint
