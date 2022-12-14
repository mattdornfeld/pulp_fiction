//
//  PostStream.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import BowEffects
import ComposableArchitecture
import Foundation
import GRPC
import Logging

/// Stream Post protos from the backend API and stores them in a ViewStore
class PostStream {
    private let getFeedRequest: GetFeedRequest
    internal let logger: Logger = .init(label: String(describing: PostStream.self))
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let enqueueAction: ([(Int, Post)]) -> Void
    private var stream: BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse>

    /// - Parameters:
    ///   - pulpFictionClientProtocol: client for the backend
    ///   - getFeedRequest: request proto for the stream
    ///   - viewStore: ViewStore in which posts will be stored so they can be rendered by the corresponding PostScrollView
    init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        enqueueAction: @escaping ([(Int, Post)]) -> Void
    ) {
        self.getFeedRequest = getFeedRequest
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.enqueueAction = enqueueAction
        stream = PostStream.buildStream(
            logger: logger,
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            enqueueAction: enqueueAction
        )
        loadMorePosts()
    }

    private static func buildStream(
        logger: Logger,
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        enqueueAction: @escaping ([(Int, Post)]) -> Void
    ) -> BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse> {
        let currentPostIndex: AtomicCounter = .init()
        logger.debug("Starting stream")
        let stream = pulpFictionClientProtocol.getFeed { getFeedResponse in

            logger.debug(
                "Received getFeedResponse",
                metadata: [
                    "thread": "\(Thread.current.hashValue)",
                    "numPosts": "\(getFeedResponse.posts.count)",
                ]
            )

            let postIndicesAndPosts = getFeedResponse.posts.map { post in
                currentPostIndex.increment()
                return (currentPostIndex.getValue(), post)
            }

            enqueueAction(postIndicesAndPosts)
        }

        stream.status.whenComplete { result in
            result.onSuccess { status in
                logger.debug(
                    "Post feed processed successfully",
                    metadata: [
                        "thread": "\(Thread.current.hashValue)",
                        "status": "\(status)",
                    ]
                )
            }.onFailure { error in
                logger.error(
                    "Error processing post feed",
                    metadata: [
                        "thread": "\(Thread.current.hashValue)",
                        "error": "\(error)",
                    ]
                )
            }
        }

        return stream
    }

    /// Closes the connection to the backend service
    func closeStream() {
        try! stream.sendEnd()
    }

    @discardableResult
    /// Send request to backend server to load more posts into stream
    func loadMorePosts() -> PostStream {
        try! stream.sendMessage(getFeedRequest).wait()
        return self
    }

    @discardableResult
    /// Ends the current stream and starts a new one
    func restartStream() -> PostStream {
        logger.debug("Restarting stream")
        stream.sendEnd()
        stream = PostStream.buildStream(
            logger: logger,
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            enqueueAction: enqueueAction
        )
        loadMorePosts()
        return self
    }
}
