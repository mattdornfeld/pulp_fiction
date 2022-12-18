//
//  PostStreamTest.swift
//  test_unit.__internal__.__test_bundle
//
//  Created by Matthew Dornfeld on 10/6/22.
//

import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

class PostStreamTest: XCTestCase {
    func testPostStreamAutoIncrementsPostsIndices() throws {
        let expectedNumElements = PostFeedConfigs.numPostReturnedPerRequest
        var postIndices: Queue<Int> = .init(maxSize: expectedNumElements)
        let postStream = try ExternalMessengers.createForTests().mapRight { externalMessengers in
            let postFeedMessenger = externalMessengers.postFeedMessenger
            return PostStream(
                pulpFictionClientProtocol: externalMessengers.postFeedMessenger.pulpFictionClientProtocol,
                getFeedRequest: postFeedMessenger.getGlobalPostFeedRequest()
            ) { newPostIndicesAndPosts in
                DispatchQueue.global(qos: .userInitiated).sync {
                    postIndices.enqueue(newPostIndicesAndPosts.map { $0.0 })
                }
            }
        }.getOrThrow()

        XCTAssertEqual(Array(1 ... expectedNumElements), postIndices.dequeue(numElements: expectedNumElements))
    }
}
