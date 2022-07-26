BAZEL=bazel

DOCKER_IMAGE_NAME := $(N)
DOCKER_IMAGE_TAG := $(T)

login_to_ecr:
	docker login -u AWS -p $$(aws ecr get-login-password) 146956608205.dkr.ecr.us-east-1.amazonaws.com

build_image:
	$(BAZEL) run //docker_images/$(DOCKER_IMAGE_NAME):build_image

build_and_push_image:
	$(BAZEL) run --define=DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_TAG) //docker_images/$(DOCKER_IMAGE_NAME):push_image
