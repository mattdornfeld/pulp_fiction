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
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let postDataMessenger: PostDataMessenger
    public let loginSession: LoginSession

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol, postDataMessenger: PostDataMessenger, loginSession: LoginSession) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.postDataMessenger = postDataMessenger
        self.loginSession = loginSession
    }

    private func getImagePostFeed(getFeedRequest: GetFeedRequest) -> PostViewFeed<ImagePostView> {
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
                imagePostViewEither <- ImagePostView.create(
                    postViewIndex: postViewIndex,
                    imagePostData: imagePostDataEither.get,
                    userPostData: userPostDataEither.get,
                    postFeedMessenger: self,
                    loggedInUserPostData: loginSession.loggedInUserPostData
                ),
                yield: imagePostViewEither.get
            )^
        }

        return PostViewFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: imagePostViewEitherSupplier
        )
    }

    /// Constructs the post feed for a user based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostView objects for a user
    func getUserProfilePostFeed(userId: UUID) -> PostViewFeed<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getUserPostFeedRequest = GetFeedRequest.GetUserPostFeedRequest.with {
                $0.userID = userId.uuidString
            }
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest)
    }

    /// Constructs the global post feed based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostView objects for the global feed
    func getGlobalPostFeed() -> PostViewFeed<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getGlobalPostFeedRequest = GetFeedRequest.GetGlobalPostFeedRequest()
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest)
    }

    func getFollowingPostFeed(userId: UUID) -> PostViewFeed<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getFollowingPostFeedRequest = GetFeedRequest.GetFollowingPostFeedRequest.with {
                $0.userID = userId.uuidString
            }
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest)
    }

    func getCommentFeed(postId: UUID) -> PostViewFeed<CommentView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
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
                commentViewEither <- CommentView.create(
                    postViewIndex: postViewIndex,
                    commentPostData: commentPostDataEither.get,
                    userPostData: userPostDataEither.get,
                    postFeedMessenger: self,
                    loggedInUserPostData: loginSession.loggedInUserPostData
                ),
                yield: commentViewEither.get
            )^
        }

        return PostViewFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            postViewEitherSupplier: commentViewEitherSupplier
        )
    }

    private func getUserConnectionScrollFeed(getFeedRequest: GetFeedRequest) -> PostViewFeed<UserConnectionView> {
        return PostViewFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest
        ) { postViewIndex, postProto in
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()

            return binding(
                userPostDataEither <- postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                yield: UserConnectionView(
                    id: postViewIndex,
                    userPostData: userPostDataEither.get,
                    postFeedMessenger: self,
                    loggedInUserPostData: loginSession.loggedInUserPostData
                )
            )^
        }
    }

    func getFollowingScrollFeed(userId: UUID) -> PostViewFeed<UserConnectionView> {
        getUserConnectionScrollFeed(getFeedRequest: GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getFollowingFeedRequest = GetFeedRequest.GetFollowingFeedRequest.with {
                $0.userID = userId.uuidString
            }
        })
    }

    func getFollowersScrollFeed(userId: UUID) -> PostViewFeed<UserConnectionView> {
        getUserConnectionScrollFeed(getFeedRequest: GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getFollowersFeedRequest = GetFeedRequest.GetFollowersFeedRequest.with {
                $0.userID = userId.uuidString
            }
        })
    }
}
