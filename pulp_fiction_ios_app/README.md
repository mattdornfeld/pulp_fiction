# Pulp Fiction IOS App
This is the subproject for the Pulp Fiction IOS App.
## Project Setup
### Configure Environment
To work on the IOS app part of the codebase you'll need to install Swift and XCode. Install Xcode from the  App Store. Then install XCode command line tools by running
```
xcode-select --install
```
### Build and Test From Command Line
This project has been tested with XCode 13.3 and Swift 5.6. All of the Bazel build and test rules for the IOS app are in the `BUILD` file of this directory. Common command line operations are stored in the `Makefile`. To build the app from the command line run
```
make build_app
```
To execute the tests run
```
make test_all
```
### Tulsi
This project uses [rules_xcodeproj](https://github.com/buildbuddy-io/rules_xcodeproj) as a tool for generating XCode projects from the Bazel `BUILD` file. To generate an `xcodeproj` from the `BUILD` file run
```
make build_xcodeproj
```
This should generate and `xcodeproj` directory. From there you open that directory in XCode and should try building the app, running tests, and opening the app in a simulator from the IDE.
