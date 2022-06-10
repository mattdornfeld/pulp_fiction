//
//  PictureSaverTests.swift
//  PictureSaverTests
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import PulpFictionApp
import SwiftProtobuf
import XCTest

extension LocalImageStore {
    @discardableResult
    func deleteDatabase() -> Result<Void, Error> {
        return Result { try FileManager.default.removeItem(at: self.databaseFileURL) }
    }
}

class LocalImageStoreTests: XCTestCase {
    private var localImageStoreMaybe: LocalImageStore?

    override func setUpWithError() throws {
        localImageStoreMaybe = try .init(databaseFileName: "\(PulpFictionUtils.generateRandomInt64()).sqlite").getOrThrow()
    }

    override func tearDownWithError() throws {
        try localImageStoreMaybe.getOrThrow().deleteDatabase()
    }

    func testGetAndPut() throws {
        let expectedImageWithMetadata = PulpFictionUtils.buildImageWithMetadata(
            imageId: 1234,
            createdAt: Google_Protobuf_Timestamp(timeIntervalSince1970: 0),
            serializedImage: Data()
        )

        let localImageStore = try localImageStoreMaybe.getOrThrow()
        let putResult = localImageStore.put(expectedImageWithMetadata)
        let imageWithMetadataResult = localImageStore.get(expectedImageWithMetadata.imageMetadata.imageID)

        XCTAssertTrue(putResult.isSuccess())
        XCTAssertTrue(imageWithMetadataResult.isSuccess())
        imageWithMetadataResult.onSuccess {
            imageWithMetadata in
            XCTAssertEqual(expectedImageWithMetadata, imageWithMetadata)
        }
    }

    func testBatchGet() throws {
        let expectedImageIds: [Int64] = [1234, 1235]
        let expectedImageWithMetadatas = expectedImageIds.map { PulpFictionUtils.buildImageWithMetadata(
            imageId: $0,
            createdAt: Google_Protobuf_Timestamp(timeIntervalSince1970: 0),
            serializedImage: Data()
        ) }

        let localImageStore = try localImageStoreMaybe.getOrThrow()
        localImageStore.put(expectedImageWithMetadatas)
        let imageWithMetadatas = try localImageStore.batchGet(expectedImageIds).get()
        XCTAssertTrue(expectedImageWithMetadatas.count > 0)
        XCTAssertEqual(expectedImageWithMetadatas, imageWithMetadatas)
    }
}
