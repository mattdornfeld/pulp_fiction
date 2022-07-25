BAZEL=bazel

build_image:
	$(BAZEL) build -s --sandbox_debug //docker_images/bazel_ci_image:build_image

build_and_push_image:
	$(BAZEL) run --define=DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_TAG) //docker_images/bazel_ci_image:push_image