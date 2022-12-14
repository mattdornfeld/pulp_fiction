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

/// Sequence of PostViews
public class PostViewFeed<A: ScrollableContentView>: Sequence {
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let getFeedRequest: GetFeedRequest
    private let postViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, A>

    public init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        postViewEitherSupplier: @escaping (Int, Post) -> Either<PulpFictionRequestError, A>
    ) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.getFeedRequest = getFeedRequest
        self.postViewEitherSupplier = postViewEitherSupplier
    }

    public func makeIterator() -> PostViewFeedIterator<A> {
        return PostViewFeedIterator(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: postViewEitherSupplier
        ).startStream()
    }
}

/// Iterator for PostViewFeed
public class PostViewFeedIterator<A: ScrollableContentView>: IteratorProtocol, Equatable {
    public typealias Element = A
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let getFeedRequest: GetFeedRequest
    private let postViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, A>
    private let logger: Logger = .init(label: String(describing: PostViewFeedIterator.self))
    private let startedAt: TimeInterval = NSDate().timeIntervalSince1970
    private var postViews: Queue<A>
    public private(set) var currentPostIndex: AtomicCounter = .init()
    public private(set) var isDone: Bool = false

    init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        postViewEitherSupplier: @escaping (Int, Post) -> Either<PulpFictionRequestError, A>
    ) {
        postViews = Queue(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
        self.getFeedRequest = getFeedRequest
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.postViewEitherSupplier = postViewEitherSupplier
    }

    public static func == (lhs: PostViewFeedIterator, rhs: PostViewFeedIterator) -> Bool {
        lhs.postViews == rhs.postViews
            && lhs.isDone == rhs.isDone
            && lhs.getFeedRequest == rhs.getFeedRequest
            && lhs.currentPostIndex.getValue() == rhs.currentPostIndex.getValue()
            && lhs.startedAt == rhs.startedAt
    }

    public class ErrorRetrievingPosts: PulpFictionRequestError {}

    func startStream() -> PostViewFeedIterator {
        logger.debug("Starting stream")
        DispatchQueue.global(qos: .userInteractive).async {
            let stream = self.pulpFictionClientProtocol.getFeed(self.getFeedRequest) { getFeedResponse in
                getFeedResponse.posts.forEach { post in

                    let currentPostIndex = self.currentPostIndex.getValue()
                    /// In unit tests postViewEitherSupplier. This likely has something to do with runnng with the DEBUG config.
                    /// Will try to find a way to remove this in the future.
                    let postViewEither = {
                        if ApplicationConfigs.isTestMode {
                            return DispatchQueue.main.sync { self.postViewEitherSupplier(currentPostIndex, post) }
                        } else {
                            return self.postViewEitherSupplier(currentPostIndex, post)
                        }
                    }()

                    postViewEither.mapRight { postView in
                        self.postViews.enqueue(postView)
                    }.onError { cause in
                        self.logger.error(
                            "Error building PostView",
                            metadata: [
                                "cause": "\(cause)",
                                "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                                "postIndex": "\(currentPostIndex)",
                            ]
                        )
                    }

                    self.currentPostIndex.increment()
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

    public func next() -> A? {
        if let postView = postViews.dequeue() {
            logger.debug("Dequeueing post")
            return postView
        } else {
            logger.debug("Finished reading post feed")
            isDone = true
            return nil
        }
    }
}
