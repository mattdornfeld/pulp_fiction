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
    private let logger: Logger = .init(label: String(describing: PostStream.self))
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private var currentPostIndex: AtomicCounter = .init()
    private var viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>

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
        self.viewStore = viewStore
        let stream = buildStream()
        try! stream.sendMessage(self.getFeedRequest).wait()
//        DispatchQueue.global(qos: .userInteractive).async {
//            while true {
//                self.postViews.blockIfNotEmpty()
//                try! stream.sendMessage(self.getFeedRequest).wait()
//            }
//        }
    }

    private func buildStream() -> BidirectionalStreamingCall<GetFeedRequest, GetFeedResponse> {
        logger.debug("Starting stream")
        let stream = pulpFictionClientProtocol.getFeed { getFeedResponse in

            self.logger.debug(
                "Received getFeedResponse",
                metadata: [
                    "thread": "\(Thread.current.hashValue)",
                    "numPosts": "\(getFeedResponse.posts.count)",
                ]
            )

            getFeedResponse.posts.forEach { post in
                let currentPostIndex = self.currentPostIndex.getValue()
                DispatchQueue.main.sync { self.viewStore.send(.enqueuePost(currentPostIndex, post)) }
                self.currentPostIndex.increment()
            }
        }

        stream.status.whenComplete { result in
            result.onSuccess { status in
                self.logger.debug(
                    "Post feed processed successfully",
                    metadata: [
                        "thread": "\(Thread.current.hashValue)",
                        "status": "\(status)",
                    ]
                )
            }.onFailure { error in
                self.logger.error(
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
}
