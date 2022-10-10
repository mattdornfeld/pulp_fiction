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
    public func getGlobalPostFeed() -> PostViewFeed<ImagePostView> {
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

    public func getCommentFeed(postId: UUID) -> PostViewFeed<CommentView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession
            $0.getCommentFeedRequest = GetFeedRequest.GetCommentFeedRequest.with {
                $0.postID = postId.uuidString
            }
        }

        let commentViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, CommentView> = { postViewIndex, postProto in
            let commentPostDataEither = Either<PulpFictionRequestError, CommentPostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let commentViewEither = Either<PulpFictionRequestError, CommentView>.var()

            return binding(
                commentPostDataEither <- postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toCommentPostData() }^,
                userPostDataEither <- postDataMessenger
                    .getPostData(postProto.comment.postCreatorLatestUserPost)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                commentViewEither <- CommentView.create(postViewIndex, commentPostDataEither.get, userPostDataEither.get),
                yield: commentViewEither.get
            )^
        }

        return PostViewFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: commentViewEitherSupplier
        )
    }
}
