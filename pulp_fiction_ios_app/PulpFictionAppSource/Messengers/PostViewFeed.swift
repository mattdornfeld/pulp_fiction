//
//  PostViewFeed.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import BowEffects
import Foundation
import GRPC
import Logging

public class PostViewFeed: Sequence {
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let getFeedRequest: GetFeedRequest
    private let postViewEitherSupplier: (Post) -> Either<PulpFictionRequestError, ImagePostView>

    public init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        postViewEitherSupplier: @escaping (Post) -> Either<PulpFictionRequestError, ImagePostView>
    ) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.getFeedRequest = getFeedRequest
        self.postViewEitherSupplier = postViewEitherSupplier
    }

    public func makeIterator() -> PostViewFeedIterator {
        return PostViewFeedIterator(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: postViewEitherSupplier
        ).startStream()
    }

    func takeAll() -> [ImagePostView] {
        var postViews: [ImagePostView] = []
        for postView in self {
            postViews.append(postView)
        }
        return postViews
    }
}

public class PostViewFeedIterator: IteratorProtocol {
    public typealias Element = ImagePostView
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let getFeedRequest: GetFeedRequest
    private let postViewEitherSupplier: (Post) -> Either<PulpFictionRequestError, ImagePostView>
    private let logger = Logger(label: String(describing: PostViewFeedIterator.self))
    private var postViews: Queue<ImagePostView>

    init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        postViewEitherSupplier: @escaping (Post) -> Either<PulpFictionRequestError, ImagePostView>
    ) {
        postViews = Queue(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
        self.getFeedRequest = getFeedRequest
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.postViewEitherSupplier = postViewEitherSupplier
    }

    public class ErrorRetrievingPosts: PulpFictionRequestError {}

    func startStream() -> PostViewFeedIterator {
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

                    self.postViewEitherSupplier(post).mapRight { postView in
                        self.postViews.enqueue(postView)
                    }.logError("Error building PostView")
                }
            }

            stream.status.whenComplete { result in
                self.postViews.close()

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

    public func next() -> ImagePostView? {
        if let postView = postViews.dequeue() {
            logger.debug("Dequeueing post")
            return postView
        } else {
            logger.debug("Finished reading post feed")
            return nil
        }
    }
}
