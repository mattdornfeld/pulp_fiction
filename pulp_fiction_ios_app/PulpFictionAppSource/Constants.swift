//
// Created by Matthew Dornfeld on 4/29/22.
//
import Foundation
import Logging

struct Constants {
    private static let logger: Logger = .init(label: String(describing: Constants.self))

    static let applicationName = "pulp-fiction"

    static let appDirectoryURL: URL = {
        let appDirectoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent(applicationName)

        do {
            try FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true)
            logger.info("Created app directory at \(appDirectoryURL)")
        } catch {
            logger.error("Error Creating app directory: \(error)")
        }

        return appDirectoryURL
    }()
}
