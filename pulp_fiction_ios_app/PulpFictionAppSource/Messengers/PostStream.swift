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
class PostStream<A: ScrollableContentView> {
    private let getFeedRequest: GetFeedRequest
    private let logger: Logger
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let stream: BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse>

    /// - Parameters:
    ///   - pulpFictionClientProtocol: client for the backend
    ///   - getFeedRequest: request proto for the stream
    ///   - viewStore: ViewStore in which posts will be stored so they can be rendered by the corresponding PostScrollView
    init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        getFeedRequest: GetFeedRequest,
        viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>
    ) {
        self.getFeedRequest = getFeedRequest
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        var currentPostIndex: AtomicCounter = .init()
        let logger: Logger = .init(label: String(describing: "PostStream"))
        self.logger = logger
        stream = {
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

                DispatchQueue.main.sync { viewStore.send(.enqueuePosts(postIndicesAndPosts)) }
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
        }()
        loadMorePosts()
    }

    /// Send request to backend server to load more posts into stream
    func loadMorePosts() {
        try! stream.sendMessage(getFeedRequest).wait()
    }
}
