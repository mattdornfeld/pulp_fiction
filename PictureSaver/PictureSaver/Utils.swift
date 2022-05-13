//
// Created by Matthew Dornfeld on 4/29/22.
//

import Foundation

struct Utils {
    static func getAppDirectoryFilePath(fileName: String) -> String {
        Constants.appDirectoryURL.path + fileName
    }
}