//
// Created by Matthew Dornfeld on 4/23/22.
//

import Foundation
import Logging
import SQLite
import UIKit

struct ImageDatabaseCompanion {
    fileprivate static let tableName = "images"
    fileprivate static let imageId: Expression<Int64> = Expression<Int64>("imageId")
    fileprivate static let image: Expression<String> = Expression<String>("image")
    fileprivate static let caption: Expression<String> = Expression<String>("caption")
    fileprivate static let createdAt: Expression<Date> = Expression<Date>("createdAt")
}

class ImageDatabase {
    private let logger: Logger = Logger(label: String(describing: ImageDatabase.self))
    private let db: Connection
    private let imagesTable: Table = Table(ImageDatabaseCompanion.tableName)
    private typealias ImageIterator = RowIterator

    init() {
        try! db = Connection(Utils.getAppDirectoryFilePath(fileName: "imageDatabase.sqlite3"))
        createImageTableIfNotExists()
    }

    private func createImageTableIfNotExists() {
        do {
            try db.run(imagesTable.create {
                table in
                table.column(ImageDatabaseCompanion.imageId, primaryKey: true)
                table.column(ImageDatabaseCompanion.image)
                table.column(ImageDatabaseCompanion.caption)
                table.column(ImageDatabaseCompanion.createdAt)
            })
        } catch let error as SQLite.Result where error.description.contains("table \"\(ImageDatabaseCompanion.tableName)\" already exists (code: 1)") {
        } catch {
            logger.error("Error creating image table: \(error)")
            exit(0)
        }
    }

    func put(imageWithCaption: ImageWithCaption) throws {
        guard let serializedImage = imageWithCaption.serializeImage() else {
            logger.warning("Error serializing image \(imageWithCaption.imageId)")
            return
        }

        let insert = imagesTable.insert(
                ImageDatabaseCompanion.imageId <- imageWithCaption.imageId,
                ImageDatabaseCompanion.image <- serializedImage,
                ImageDatabaseCompanion.caption <- imageWithCaption.caption,
                ImageDatabaseCompanion.createdAt <- imageWithCaption.createdAt
        )
        try db.run(insert)
    }

    private func getImageIterator() throws -> ImageIterator {
        let imagesQuery = imagesTable.order(ImageDatabaseCompanion.createdAt.desc)
        return try db.prepareRowIterator(imagesQuery)
    }

    func getImageWithCaptions() throws -> [ImageWithCaption] {
        try getImageIterator().map {
                    (row: SQLite.Row) -> ImageWithCaption? in
                    let imageId = row[ImageDatabaseCompanion.imageId]
                    let imageData = Data(
                            base64Encoded: row[ImageDatabaseCompanion.image], options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                    let caption = row[ImageDatabaseCompanion.caption]
                    let createdAt = row[ImageDatabaseCompanion.createdAt]

                    if let uiImage = UIImage(data: imageData) {
                        return ImageWithCaption(
                                imageId: imageId,
                                uiImage: uiImage,
                                caption: caption,
                                createdAt: createdAt)
                    } else {
                        logger.error("Error loading image \(imageId)")
                        return nil
                    }
                }
                .compactMap {
                    $0
                }

    }
}
