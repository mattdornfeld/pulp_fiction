BAZEL=bazel

terraform_init:
	$(BAZEL) run :root_module init

terraform_format:
	$(BAZEL) run :root_module fmt -- -recursive

terraform_build:
	$(BAZEL) build :root_module

terraform_test:
	$(BAZEL) test ...

terraform_plan:
	$(BAZEL) run :root_module plan

terraform_apply:
	$(BAZEL) run :root_module apply