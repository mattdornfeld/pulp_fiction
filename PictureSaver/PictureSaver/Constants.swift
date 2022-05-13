//
// Created by Matthew Dornfeld on 4/29/22.
//

import Foundation

struct Constants {
    static let appDirectoryURL: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

    static let imageDatabase: ImageDatabase = ImageDatabase()
}
