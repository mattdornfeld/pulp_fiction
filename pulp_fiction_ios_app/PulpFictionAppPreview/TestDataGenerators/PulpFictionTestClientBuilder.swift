//
//  PulpFictionTestClientBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/22/22.
//

import Foundation
import Logging
import PulpFictionAppSource

/// PulpFictionTestClientBuilder builds a PulpFictionTestClient
public struct PulpFictionTestClientBuilder {
    /// Number of posts that will be included in feed response
    let numPostsInFeedResponse: Int
    private let queue = DispatchQueue(label: "queue.pulpFictionTestClient")
    private let logger: Logger = .init(label: String(describing: PulpFictionTestClientBuilder.self))

    private func generatePostsForFeed() -> [Post] {
        (0 ..< numPostsInFeedResponse).map { _ in Post.generate(Post.PostType.image) }
    }

    private func generateGetFeedResponse() -> GetFeedResponse {
        GetFeedResponse.with {
            $0.posts = generatePostsForFeed()
        }
    }

    /// Builds a PulpFictionTestClient
    public func build() -> PulpFictionTestClient {
        let pulpFictionTestClient = PulpFictionTestClient()
        pulpFictionTestClient.enqueueGetFeedResponses([generateGetFeedResponse()])

        DispatchQueue.global(qos: .userInteractive).async {
            while true {
                queue.sync {
                    if !pulpFictionTestClient.hasGetFeedResponsesRemaining {
                        logger.info("Adding \(numPostsInFeedResponse) posts to GetFeedResponse stub")
                        pulpFictionTestClient.enqueueGetFeedResponses([generateGetFeedResponse()])
                    }
                }

                Thread.sleep(forTimeInterval: 0.05)
            }
        }

        return pulpFictionTestClient
    }
}
