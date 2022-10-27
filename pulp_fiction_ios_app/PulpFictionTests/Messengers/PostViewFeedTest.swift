//
//  PostViewFeedTest.swift
//  test_unit.__internal__.__test_bundle
//
//  Created by Matthew Dornfeld on 10/6/22.
//

import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

extension PostViewFeedIterator {
    func takeAll() -> [A] {
        var postViews: [A] = []
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

    func testRetrievingAllItemsFromCommentViewFeed() throws {
        let expectedNumPostsInFeedResponse = 50
        let expectedPostId = UUID()
        let postViewFeedIterator = try ExternalMessengers.createForTests(numPostsInFeedResponse: expectedNumPostsInFeedResponse).mapRight { externalMessengers in
            externalMessengers.postFeedMessenger.getCommentFeed(postId: expectedPostId)
        }
        .getOrThrow()
        .makeIterator()
        let postViews = postViewFeedIterator.takeAll()

        let comments = Set(postViews.map { postView in postView.commentPostData.body })
        XCTAssertEqual(1, comments.count)
        XCTAssertTrue(comments.contains(FakeData.comment))

        let postIds = Set(postViews.map { postView in postView.commentPostData.parentPostId })
        XCTAssertEqual(1, postIds.count)
        XCTAssertTrue(postIds.contains(expectedPostId))

        XCTAssertEqual(expectedNumPostsInFeedResponse, postViews.count)
        XCTAssertEqual(Array(0 ..< expectedNumPostsInFeedResponse), postViews.map { postView in postView.id })
        XCTAssertTrue(postViewFeedIterator.isDone)
    }
}
