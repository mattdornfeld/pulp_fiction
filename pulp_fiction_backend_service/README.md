# Pulp Fiction Backend Service
This is the subproject for Pulp Fiction backend service

# Project Setup
## Configure Environment
Install Java 17 with the following command
```
brew install openjdk@17
```
It is recommended that you use IntelliJ for development. A download link can be found [here](https://www.jetbrains.com/idea/download/#section=mac). After opening IntelliJ you can import the project settings from the `intellij_settings.zip` file in this directory. The click on `Import Bazel Project` in the File menu and select the `BUILD` file in this directory. Once the project is loaded click `Sync Project With BUILD Files` in the Bazel/Sync menu. Now you should be able to build the project and run tests from the IDE.
### Build and Test From Command Line
To build the project run
```
make build_jar
```
To run the tests run
```
make test_all
```
To start the backend server locally run
```
make run_locally
```