//
// Created by Matthew Dornfeld on 4/23/22.
//
import Foundation
import Logging
import SQLite
import SwiftUI
import UIKit

extension RowIterator {
    func mapToResult<Success, Failure: Error>(_ transform: (SQLite.RowIterator.Element) -> Swift.Result<Success, Failure>) -> [Swift.Result<Success, Failure>] {
        var results: [Swift.Result<Success, Failure>] = []
        while true {
            if let element = next() {
                results.append(transform(element))
            } else {
                return results
            }
        }
    }
}

struct LocalImageStoreCompanion {
    fileprivate static let tableName = "images"
    fileprivate static let imageId: Expression<Int64> = .init("imageId")
    fileprivate static let imageWithMetadata: Expression<String> = .init("image")
    fileprivate static let imagesTable: Table = .init(tableName)
    private static let logger: Logger = .init(label: String(describing: LocalImageStoreCompanion.self))

    fileprivate static func createDatabaseConnection(_ databaseFileURL: URL) -> Swift.Result<Connection, Error> {
        Swift.Result { try Connection(databaseFileURL.path) }
            .onFailure { error in logger.error(
                "Error creating database connection",
                metadata: [
                    "cause": "\(error)",
                ]
            ) }
    }

    fileprivate static func createTableIfNotExists(_ connection: Connection, _ imagesTable: Table) -> Swift.Result<Connection, Error> {
        return Swift.Result {
            try connection.run(imagesTable.create(ifNotExists: true) {
                table in
                table.column(LocalImageStoreCompanion.imageId, primaryKey: true)
                table.column(LocalImageStoreCompanion.imageWithMetadata)
            })
            return connection
        }.onFailure { error in logger.error(
            "Error creating table",
            metadata: [
                "table": "\(tableName)",
                "cause": "\(error)",
            ]
        ) }
    }
}

public class LocalImageStore {
    public let databaseFileURL: URL
    private let connection: Connection
    private let logger: Logger = .init(label: String(describing: LocalImageStore.self))
    private typealias ImageWithMetadataIterator = RowIterator

    public init?(databaseFileName: String) {
        databaseFileURL = PulpFictionUtils.getAppDirectoryFileURL(fileName: databaseFileName)
        switch LocalImageStoreCompanion
            .createDatabaseConnection(databaseFileURL)
            .flatMap({ _connection in LocalImageStoreCompanion.createTableIfNotExists(_connection, LocalImageStoreCompanion.imagesTable) })
        {
        case let .success(_connection):
            connection = _connection
        case .failure:
            return nil
        }

        logger.info(
            "Created database",
            metadata: [
                "url": "\(databaseFileURL)",
            ]
        )
    }

    convenience init?() {
        self.init(databaseFileName: "imageDatabase.sqlite3")
    }

    private func buildSerializedImageResult(_ imageWithMetadata: ImageWithMetadata) -> Swift.Result<String, Error> {
        return Swift.Result { try imageWithMetadata.serializedData() }
            .onFailure { error in
                logger.error(
                    "Error serializing object",
                    metadata: [
                        "objectType": "\(ImageWithMetadata.self)",
                        "imageId": "\(imageWithMetadata.imageMetadata.imageID)",
                        "cause": "\(error)",
                    ]
                )
            }.map { $0.base64EncodedString() }
    }

    public enum PutImageWithMetadataError: Error {
        case errorSerializingImageWithMetadatas
        case errorSerializingSomeImageWithMetadatas
        case errorWritingToDatabase(Error)
    }

    @discardableResult
    public func put(_ imageWithMetadata: ImageWithMetadata) -> Swift.Result<Void, PutImageWithMetadataError> {
        return put([imageWithMetadata])
    }

    private func buildInsertImageStatement(_ imageWithMetadata: ImageWithMetadata, _ serializedImage: String) -> [Setter] {
        return [
            LocalImageStoreCompanion.imageId <- imageWithMetadata.imageMetadata.imageID,
            LocalImageStoreCompanion.imageWithMetadata <- serializedImage,
        ]
    }

    @discardableResult
    public func put(_ imageWithMetadatas: [ImageWithMetadata]) -> Swift.Result<Void, PutImageWithMetadataError> {
        let imageWithMetadataAndSerializedImageResults = imageWithMetadatas
            .map { ($0, buildSerializedImageResult($0)) }

        let idsOfSerializationFailures = imageWithMetadataAndSerializedImageResults
            .map { (imageWithMetadata: ImageWithMetadata, serializedImageResult: Swift.Result<String, Error>) -> Int64? in
                switch serializedImageResult {
                case .success:
                    return nil
                case .failure:
                    return imageWithMetadata.imageMetadata.imageID
                }
            }
            .compactMap { $0 }

        if idsOfSerializationFailures.count == imageWithMetadatas.count {
            return Swift.Result.failure(PutImageWithMetadataError.errorSerializingImageWithMetadatas)
        }

        let serializationResult = idsOfSerializationFailures.count > 0 ?
            Swift.Result.failure(PutImageWithMetadataError.errorSerializingSomeImageWithMetadatas) :
            Swift.Result.success(())

        let insertStatementsWithImageIds = imageWithMetadataAndSerializedImageResults
            .map { (imageWithMetadata: ImageWithMetadata, serializedImageResult: Swift.Result<String, Error>) -> (Int64, [Setter])? in
                switch serializedImageResult {
                case let .success(serializedImage):
                    return (imageWithMetadata.imageMetadata.imageID, buildInsertImageStatement(imageWithMetadata, serializedImage))
                case .failure:
                    return nil
                }
            }
            .compactMap { $0 }

        let databaseInsertResult = Swift.Result { try connection.run(LocalImageStoreCompanion.imagesTable.insertMany(insertStatementsWithImageIds.map { _, insertStatement in insertStatement })) }
            .onFailure { error in
                insertStatementsWithImageIds.forEach { imageId, _ in
                    logger.info(
                        "Error inserting object",
                        metadata: [
                            "objectType": "\(ImageWithMetadata.self)",
                            "imageId": "\(imageId)",
                            "cause": "\(error)",
                        ]
                    )
                }
            }
            .onSuccess { () in
                insertStatementsWithImageIds.forEach { imageId, _ in
                    logger.info(
                        "Inserted object to database",
                        metadata: [
                            "objectType": "\(ImageWithMetadata.self)",
                            "imageId": "\(imageId)",
                        ]
                    )
                }
            }
            .mapError { PutImageWithMetadataError.errorWritingToDatabase($0) }

        if databaseInsertResult.isSuccess(), serializationResult.isFailure() {
            return serializationResult
        } else {
            return databaseInsertResult
        }
    }

    public enum GetImageWithMetadataError: Error {
        case errorReadingDatabase(Error)
        case imageIdNotFound
        case errorDeserializingImageWithMetadata(Error)
        case invalidSerializationFormat
    }

    private func getImageWithMetadataFromRow(_ row: SQLite.Row) -> Swift.Result<ImageWithMetadata, GetImageWithMetadataError> {
        let imageId = row[LocalImageStoreCompanion.imageId]

        return Data(base64Encoded: row[LocalImageStoreCompanion.imageWithMetadata])
            .toResult(GetImageWithMetadataError.invalidSerializationFormat)
            .onFailure { _ in
                logger.error(
                    "Object stored in database has an invalid serialization format",
                    metadata: [
                        "objectType": "\(ImageWithMetadata.self)",
                        "imageId": "\(imageId)",
                    ]
                )
            }
            .flatMap { serializedData in
                Swift.Result { try ImageWithMetadata(serializedData: serializedData) }
                    .mapError { error in GetImageWithMetadataError.errorDeserializingImageWithMetadata(error) }
                    .onFailure { _ in
                        logger.error(
                            "Error deserializing object",
                            metadata: [
                                "objectType": "\(ImageWithMetadata.self)",
                                "imageId": "\(imageId)",
                            ]
                        )
                    }
            }
    }

    public func get(_ imageId: Int64) -> Swift.Result<ImageWithMetadata, GetImageWithMetadataError> {
        return Swift.Result {
            try connection.pluck(LocalImageStoreCompanion.imagesTable.filter(LocalImageStoreCompanion.imageId == imageId))
        }
        .mapError { error in GetImageWithMetadataError.errorReadingDatabase(error) }
        .flatMap { rowMaybe in
            rowMaybe
                .map { row in Swift.Result.success(row) }
                .getOrElse(Swift.Result.failure(GetImageWithMetadataError.imageIdNotFound))
        }.flatMap { row in
            getImageWithMetadataFromRow(row)
        }
        .onSuccess { _ in
            logger.info(
                "Retrieved object from database",
                metadata: [
                    "objectType": "\(ImageWithMetadata.self)",
                    "imageId": "\(imageId)",
                ]
            )
        }
    }

    public enum BatchGetImageWithMetadataError: Error {
        case errorRetrievingImageWithMetadatas
        case errorGettingDatabaseRowIterator(Error)
    }

    private func getImageWithMetadataIteratorResult(_ imagesTable: Table) -> Swift.Result<ImageWithMetadataIterator, BatchGetImageWithMetadataError> {
        return Swift.Result { try connection.prepareRowIterator(imagesTable) }
            .mapError { error in
                logger.error(
                    "Error creating database row iterator",
                    metadata: [
                        "cause": "\(error)",
                    ]
                )
                return BatchGetImageWithMetadataError.errorGettingDatabaseRowIterator(error)
            }
    }

    private func batchGet(_ imagesTable: Table) -> Swift.Result<[ImageWithMetadata], BatchGetImageWithMetadataError> {
        let imageWithMetadataIteratorResult = getImageWithMetadataIteratorResult(imagesTable)

        switch imageWithMetadataIteratorResult {
        case .failure:
            return imageWithMetadataIteratorResult.map { _ in [] }
        case let .success(imageWithMetadataIterator):
            let imageWithMetaDataResults: [Swift.Result<ImageWithMetadata, GetImageWithMetadataError>] = imageWithMetadataIterator.mapToResult { row in getImageWithMetadataFromRow(row) }
            let imageWithMetadatas = imageWithMetaDataResults.compactMap { $0.toOption() }

            if imageWithMetadatas.count == 0 {
                return Swift.Result.failure(BatchGetImageWithMetadataError.errorRetrievingImageWithMetadatas)
            } else {
                return Swift.Result.success(imageWithMetadatas)
            }
        }
    }

    public func batchGet(_ imageIds: [Int64]) -> Swift.Result<[ImageWithMetadata], BatchGetImageWithMetadataError> {
        return batchGet(LocalImageStoreCompanion.imagesTable.filter(imageIds.contains(LocalImageStoreCompanion.imageId)))
    }

    public func batchGet() -> Swift.Result<[ImageWithMetadata], BatchGetImageWithMetadataError> {
        return batchGet(LocalImageStoreCompanion.imagesTable)
    }
}
