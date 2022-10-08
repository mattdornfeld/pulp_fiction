//
//  PostViewFeedTest.swift
//  test_unit.__internal__.__test_bundle
//
//  Created by Matthew Dornfeld on 10/6/22.
//

import Foundation
import PulpFictionAppPreview
import PulpFictionAppSource
import XCTest

extension PostViewFeedIterator {
    func takeAll() -> [ImagePostView] {
        var postViews: [ImagePostView] = []
        var postViewMaybe = next()
        while postViewMaybe != nil {
            postViewMaybe.map { postView in postViews.append(postView) }
            postViewMaybe = next()
        }
        return postViews
    }
}

class PostViewFeedTest: XCTestCase {
    func testRetrievingAllItemsFromPostViewFeed() throws {
        let expectedNumPostsInFeedResponse = 50
        let postViewFeedIterator = try ExternalMessengers.createForTests(numPostsInFeedResponse: expectedNumPostsInFeedResponse).mapRight { externalMessengers in
            externalMessengers.postFeedMessenger.getGlobalPostFeed()
        }
        .getOrThrow()
        .makeIterator()
        let postViews = postViewFeedIterator.takeAll()

        XCTAssertEqual(expectedNumPostsInFeedResponse, postViews.count)
        XCTAssertEqual(Array(0 ..< expectedNumPostsInFeedResponse), postViews.map { postView in postView.id })
        XCTAssertTrue(postViewFeedIterator.isDone)
    }
}
