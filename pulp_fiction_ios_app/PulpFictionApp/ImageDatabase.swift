//
// Created by Matthew Dornfeld on 4/23/22.
//

import Foundation
import Logging
import protos_pulp_fiction_proto
import SQLite
import UIKit

struct ImageDatabaseCompanion {
    fileprivate static let tableName = "images"
    fileprivate static let imageId: Expression<Int64> = .init("imageId")
    fileprivate static let imageWithMetadata: Expression<String> = .init("image")
}

class ImageDatabase {
    private let logger: Logger = .init(label: String(describing: ImageDatabase.self))
    private let db: Connection
    private let imagesTable: Table = .init(ImageDatabaseCompanion.tableName)
    private typealias ImageWithMetadataIterator = RowIterator
    typealias ImageWithMetadata = PulpFiction_Protos_ImageWithMetadata

    init() {
        try! db = Connection(Utils.getAppDirectoryFilePath(fileName: "imageDatabase.sqlite3"))
        createTableIfNotExists()
    }

    private func createTableIfNotExists() {
        do {
            try db.run(imagesTable.create {
                table in
                table.column(ImageDatabaseCompanion.imageId, primaryKey: true)
                table.column(ImageDatabaseCompanion.imageWithMetadata)
            })
        } catch let error as SQLite.Result where error.description.contains("table \"\(ImageDatabaseCompanion.tableName)\" already exists (code: 1)") {
        } catch {
            logger.error("Error creating image table: \(error)")
            exit(0)
        }
    }

    func put(imageWithMetadata: ImageWithMetadata) throws {
        guard let serializedImage = try? imageWithMetadata.serializedData().base64EncodedString() else {
            logger.error("Error serializing ImageWithMetadata \(imageWithMetadata.imageMetadata.imageID)")
            return
        }

        let insert = imagesTable.insert(
            ImageDatabaseCompanion.imageId <- imageWithMetadata.imageMetadata.imageID,
            ImageDatabaseCompanion.imageWithMetadata <- serializedImage
        )
        try db.run(insert)
        
        logger.debug("Inserted \(ImageWithMetadata.self) \(imageWithMetadata.imageMetadata.imageID)")
    }

    private func getImageWithMetadataIterator() throws -> ImageWithMetadataIterator {
        return try db.prepareRowIterator(imagesTable)
    }

    func getImageWithMetadatas() throws -> [ImageWithMetadata] {
        try getImageWithMetadataIterator().map {
            (row: SQLite.Row) -> ImageWithMetadata? in
                let imageId = row[ImageDatabaseCompanion.imageId]

                guard let serializedData = Data(base64Encoded: row[ImageDatabaseCompanion.imageWithMetadata]) else {
                    logger.error("Error retreiving \(ImageWithMetadata.self) from database for image \(imageId)")
                    return nil
                }

                guard let imageWithMetadata = try? ImageWithMetadata(serializedData: serializedData) else {
                    logger.error("Error deserializing \(ImageWithMetadata.self) for image \(imageId)")
                    return nil
                }

                return imageWithMetadata
        }
        .compactMap {
            $0
        }
        .sorted {
            $0.imageMetadata.createdAt.seconds > $1.imageMetadata.createdAt.seconds
        }
    }
}
