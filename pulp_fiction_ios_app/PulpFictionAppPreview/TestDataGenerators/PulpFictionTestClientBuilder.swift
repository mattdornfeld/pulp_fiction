//
//  PulpFictionTestClientBuilder.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/22/22.
//

import Foundation
import PulpFictionAppSource

public struct PulpFictionTestClientBuilder {
    let numPostsInFeedResponse: Int

    private func generatePostsForFeed() -> [Post] {
        (1 ..< numPostsInFeedResponse).map { _ in Post.generate(Post.PostType.image) }
    }

    private func generateGetFeedResponse() -> GetFeedResponse {
        GetFeedResponse.with {
            $0.posts = generatePostsForFeed()
        }
    }

    func build() -> PulpFictionTestClient {
        let pulpFictionTestClient = PulpFictionTestClient()
        pulpFictionTestClient.enqueueGetFeedResponses([generateGetFeedResponse()])

        return pulpFictionTestClient
    }
}
