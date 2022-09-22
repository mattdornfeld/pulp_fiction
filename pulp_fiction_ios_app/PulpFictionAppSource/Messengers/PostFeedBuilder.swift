//
//  PostFeedBuilder.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import DequeModule
import Foundation
import GRPC

struct PostFeedBuilder: AsyncSequence {
    typealias Element = Post
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    let getFeedRequest: GetFeedRequest

    struct PostFeed: AsyncIteratorProtocol {
        private let stream: BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse>
        private let getFeedRequest: GetFeedRequest
        private var posts: Deque<Post> = []

        init(pulpFictionClientProtocol: PulpFictionClientProtocol, getFeedRequest: GetFeedRequest) {
            var posts: Deque<Post> = Deque()
            stream = pulpFictionClientProtocol.getFeed { getFeedResponse in
                getFeedResponse.posts.forEach { post in
                    posts.prepend(post)
                }
            }
            self.posts = posts
            self.getFeedRequest = getFeedRequest
        }

        func closeStream() {
            stream.sendEnd()
        }

        mutating func next() async -> Post? {
            if posts.isEmpty {
                stream.sendMessage(getFeedRequest)
            }

            return posts.popLast()
        }
    }

    func makeAsyncIterator() -> PostFeed {
        return PostFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest
        )
    }
}
