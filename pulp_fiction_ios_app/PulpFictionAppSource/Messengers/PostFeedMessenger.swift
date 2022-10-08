//
//  PostFeedMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/1/22.
//

import Bow
import Foundation

/// Communicates with the backend API, post data cache, and remote post data store to construct post feeds
public struct PostFeedMessenger {
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let postDataMessenger: PostDataMessenger
    private let loginSession = LoginSession.with { _ in }

    public init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        postDataMessenger: PostDataMessenger
    ) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.postDataMessenger = postDataMessenger
    }

    /// Constructs the global post feed based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostProto objects for the global feed
    public func getGlobalPostFeed() -> PostViewFeed {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession
            $0.getGlobalFeedRequest = GetFeedRequest.GetGlobalFeedRequest()
        }

        let imagePostViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, ImagePostView> = { postViewIndex, postProto in
            let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let imagePostViewEither = Either<PulpFictionRequestError, ImagePostView>.var()

            return binding(
                imagePostDataEither <- postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toImagePostData() }^,
                userPostDataEither <- postDataMessenger
                    .getPostData(postProto.imagePost.postCreatorLatestUserPost)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                imagePostViewEither <- ImagePostView.create(postViewIndex, imagePostDataEither.get, userPostDataEither.get),
                yield: imagePostViewEither.get
            )^
        }

        return PostViewFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: imagePostViewEitherSupplier
        )
    }
}
