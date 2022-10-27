//
//  PostDataCacheTests.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//
import Bow
import BowEffects
import Foundation
import PulpFictionAppPreview
import XCTest

@testable import PulpFictionAppSource

class PostDataCacheTests: XCTestCase {
    let postDataCacheMaybe = PostDataCache.create()
        .unsafeRunSyncEither()
        .mapRight { postDataCache in Option.some(postDataCache) }
        .getOrElse(Option.none())

    override func setUpWithError() throws {
        try postDataCacheMaybe
            .getOrThrow()
            .clearCache()
            .unsafeRunSync()
    }

    func testPutAndGet() throws {
        let postDataCache = try postDataCacheMaybe.getOrThrow()
        let expectedPostData = try ImagePostData.generate().getOrThrow()
        let PostUpdateIdentifier = expectedPostData.postMetadata.postUpdateIdentifier

        let putResult = IO<PulpFictionRequestError, PostMetadata>.var()
        let getResult = IO<PulpFictionRequestError, Option<PostDataOneOf>>.var()
        let postDataOneOf = try binding(
            putResult <- postDataCache.put(PostUpdateIdentifier, expectedPostData),
            getResult <- postDataCache.get(PostUpdateIdentifier),
            yield: getResult.get
        )^
            .unsafeRunSync()
            .getOrThrow()

        XCTAssertEqual(expectedPostData.toPostDataOneOf(), postDataOneOf)
    }

    func testPutAllBulkGet() throws {
        let postDataCache = try postDataCacheMaybe.getOrThrow()
        let expectedPostDatas = try [ImagePostData.generate().getOrThrow(), ImagePostData.generate().getOrThrow()]
        let items = expectedPostDatas.map { postData in (postData.postMetadata.postUpdateIdentifier, postData) }
        let PostUpdateIdentifiers = expectedPostDatas.map { postData in postData.postMetadata.postUpdateIdentifier }

        let putResult = IO<PulpFictionRequestError, [PostMetadata]>.var()
        let batchGetResult = IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.var()
        let postDataOneOfs = try binding(
            putResult <- postDataCache.putAll(items),
            batchGetResult <- postDataCache.bulkGet(PostUpdateIdentifiers),
            yield: batchGetResult.get
        )^
            .unsafeRunSync()
            .map { postDataOneOfMaybe in try postDataOneOfMaybe.getOrThrow() }

        XCTAssertEqual(expectedPostDatas.map { expectedPostData in expectedPostData.toPostDataOneOf() }, postDataOneOfs)
    }
}
