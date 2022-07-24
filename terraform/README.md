# Pulp Fiction Terraform
The cloud infrastructure for the app is managed using the Terraform code in this subproject. Bazel is used to manage the Terraform dependencies so we don't need to worry about install the Terraform binaries.

# Formatting
Before pushing your changes to a branch run
```
make terraform_format
```
to ensure the changes are formatted correctly

# CircleCI
The Terraform tests, plan, and apply are run automatically as part of the CI process. To test your changes you can push them to a branch an open a PR. The format tests, validation tests, and Terraform plan will be run in CI. You can see the output of these steps in the CircleCI logs. To apply your changes merge the branch to master.

# Command Line
To run Terraform operations from the command line you need to export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables. After that run `make terraform_init` to init the Terraform state locally. From there you can use the `terraform_test`, `terraform_plan`, and `terraform_apply` `make` targets to run tests, plans, and applies respectively. For the most part you should not run applies from the command line and let them run via CI.  