//
//  PostDataCacheTests.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//
import Bow
import BowEffects
import PulpFictionApp
import Foundation
import XCTest

class PostDataCacheTests: XCTestCase {
    let postDataCacheMaybe = PostDataCache.create()
        .unsafeRunSyncEither()
        .mapRight{postDataCache in Option.some(postDataCache)}
        .getOrElse(Option.none())
    
    override func setUpWithError() throws {
        try postDataCacheMaybe
            .getOrThrow()
            .clearCache()
            .unsafeRunSync()
    }
    
    func testPutAndGet() throws {
        let postDataCache = try postDataCacheMaybe.getOrThrow()
        let expectedPostData = ImagePostData.generate()
        let postId = expectedPostData.postMetadata.postId
        
        let putResult = IO<PulpFictionRequestError, PostMetadata>.var()
        let getResult = IO<PulpFictionRequestError, Option<PostDataOneOf>>.var()
        let postDataOneOf = try binding(
            putResult <- postDataCache.put(postId, expectedPostData),
            getResult <- postDataCache.get(postId),
            yield: getResult.get
        )^
            .unsafeRunSync()
            .getOrThrow()
        
        XCTAssertEqual(expectedPostData.toPostDataOneOf(), postDataOneOf)
    }
    
    func testPutAllBulkGet() throws {
        let postDataCache = try postDataCacheMaybe.getOrThrow()
        let expectedPostDatas = [ImagePostData.generate(), ImagePostData.generate()]
        let items = expectedPostDatas.map{postData in (postData.postMetadata.postId, postData)}
        let postIds = expectedPostDatas.map{postData in postData.postMetadata.postId}
        
        let putResult = IO<PulpFictionRequestError, [PostMetadata]>.var()
        let batchGetResult = IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.var()
        let postDataOneOfs = try binding(
            putResult <- postDataCache.putAll(items),
            batchGetResult <- postDataCache.bulkGet(postIds),
            yield: batchGetResult.get
        )^
            .unsafeRunSync()
            .map{postDataOneOfMaybe in try postDataOneOfMaybe.getOrThrow()}
        
        XCTAssertEqual(expectedPostDatas.map{expectedPostData in expectedPostData.toPostDataOneOf()}, postDataOneOfs)
    }
}
