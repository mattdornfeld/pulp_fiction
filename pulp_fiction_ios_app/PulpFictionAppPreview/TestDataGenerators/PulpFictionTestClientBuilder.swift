//
//  PulpFictionTestClientBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/22/22.
//

import Foundation
import PulpFictionAppSource

/// PulpFictionTestClientBuilder builds a PulpFictionTestClient
public struct PulpFictionTestClientBuilder {
    /// Number of posts that will be included in feed response
    let numPostsInFeedResponse: Int

    private func generatePostsForFeed() -> [Post] {
        (0 ..< numPostsInFeedResponse).map { _ in Post.generate(Post.PostType.image) }
    }

    private func generateGetFeedResponse() -> GetFeedResponse {
        GetFeedResponse.with {
            $0.posts = generatePostsForFeed()
        }
    }

    /// Builds a PulpFictionTestClient
    func build() -> PulpFictionTestClient {
        let pulpFictionTestClient = PulpFictionTestClient()
        pulpFictionTestClient.enqueueGetFeedResponses([generateGetFeedResponse()])

        return pulpFictionTestClient
    }
}
