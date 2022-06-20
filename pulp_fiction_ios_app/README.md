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
This project uses [Tulsi](https://tulsi.bazel.build/docs/gettingstarted.html) as a tool for generating XCode projects from the Bazel `BUILD` file. Follow the installation instruction in the link and open the Tulsi UI. Add the `BUILD` file in this directory as a Tulsi Bazel Package. Then click on the Configs tab. Click the + icon and select the `build_app` and `test_unit` labels. Click "Next" twice and select `bazel-out`, `external`, and `pulp_fiction_ios_app` as "Source Targets", click "Save", and choose a name for the config. Then highlight the config you just created and click "Generate". Choose this directory as the output directory and click "Generate" again. This will generate the `.xcodeproj` file and should automatically open the XCode IDE. In the future you can open the project by pointing XCode at the `.xcodeproj` file, but you will need to regenerate the file if you add new dependencies. The idea is that the `BUILD` file is the source of truth and the `.xcodeproj` file is created from the `BUILD` file. Once you have the project open in the IDE try building it and running it in a simulator.  
