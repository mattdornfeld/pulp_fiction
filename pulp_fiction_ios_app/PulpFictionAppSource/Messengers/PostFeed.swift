//
//  PostFeedBuilder.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import BowEffects
import Foundation
import GRPC
import Logging

struct PostFeed: Sequence {
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    let getFeedRequest: GetFeedRequest

    func makeIterator() -> PostFeedIterator {
        return PostFeedIterator(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest
        ).startStream()
    }

    func takeAll() -> [Post] {
        var posts: [Post] = []
        for post in self {
            posts.append(post)
        }
        return posts
    }
}

class PostFeedIterator: IteratorProtocol {
    typealias Element = Post
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    let getFeedRequest: GetFeedRequest
    private let logger = Logger(label: String(describing: PostFeedIterator.self))
    private var posts: Queue<Post>

    init(pulpFictionClientProtocol: PulpFictionClientProtocol, getFeedRequest: GetFeedRequest) {
        posts = Queue(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
        self.getFeedRequest = getFeedRequest
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
    }

    public class ErrorRetrievingPosts: PulpFictionRequestError {}

    func startStream() -> PostFeedIterator {
        logger.debug("Starting stream")
        DispatchQueue.global(qos: .userInteractive).async {
            let stream = self.pulpFictionClientProtocol.getFeed(self.getFeedRequest) { getFeedResponse in
                getFeedResponse.posts.forEach { post in
                    self.logger.debug(
                        "Enqueueing post",
                        metadata: [
                            "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                        ]
                    )
                    self.posts.enqueue(post)
                }
            }

            stream.status.whenComplete { result in
                self.posts.close()

                result.onSuccess { status in
                    self.logger.debug(
                        "Post feed processed successfully",
                        metadata: [
                            "status": "\(status)",
                        ]
                    )
                }.onFailure { error in
                    self.logger.debug(
                        "Error processing post feed",
                        metadata: [
                            "error": "\(error)",
                        ]
                    )
                }
            }
        }

        return self
    }

    func next() -> Post? {
        if let post = posts.dequeue() {
            logger.debug(
                "Dequeueing post",
                metadata: [
                    "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                ]
            )
            return post
        } else {
            logger.debug("Finished reading post feed")
            return nil
        }
    }
}
