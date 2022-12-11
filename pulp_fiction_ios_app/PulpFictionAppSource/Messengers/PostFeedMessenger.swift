//
//  PostFeedMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/1/22.
//

import Bow
import ComposableArchitecture
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

    private func getImagePostFeed(
        getFeedRequest: GetFeedRequest,
        viewStore: ViewStore<ContentScrollViewReducer<ImagePostView>.State, ContentScrollViewReducer<ImagePostView>.Action>
    ) -> PostStream<ImagePostView> {
        return PostStream(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            viewStore: viewStore
        )
    }

    /// Constructs the post feed for a user based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostView objects for a user
    func getUserProfilePostFeed(
        userId: UUID,
        viewStore: ViewStore<ContentScrollViewReducer<ImagePostView>.State, ContentScrollViewReducer<ImagePostView>.Action>
    ) -> PostStream<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getUserPostFeedRequest = GetFeedRequest.GetUserPostFeedRequest.with {
                $0.userID = userId.uuidString
            }
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest, viewStore: viewStore)
    }

    /// Constructs the global post feed based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostView objects for the global feed
    func getGlobalPostFeed(viewStore: ViewStore<ContentScrollViewReducer<ImagePostView>.State, ContentScrollViewReducer<ImagePostView>.Action>) -> PostStream<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getGlobalPostFeedRequest = GetFeedRequest.GetGlobalPostFeedRequest()
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest, viewStore: viewStore)
    }

    func getFollowingPostFeed(
        userId: UUID,
        viewStore: ViewStore<ContentScrollViewReducer<ImagePostView>.State, ContentScrollViewReducer<ImagePostView>.Action>
    ) -> PostStream<ImagePostView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getFollowingPostFeedRequest = GetFeedRequest.GetFollowingPostFeedRequest.with {
                $0.userID = userId.uuidString
            }
        }

        return getImagePostFeed(getFeedRequest: getFeedRequest, viewStore: viewStore)
    }

    func getCommentFeed(
        postId: UUID,
        viewStore: ViewStore<ContentScrollViewReducer<CommentView>.State, ContentScrollViewReducer<CommentView>.Action>
    ) -> PostStream<CommentView> {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.getCommentFeedRequest = GetFeedRequest.GetCommentFeedRequest.with {
                $0.postID = postId.uuidString
            }
        }

        return PostStream(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            viewStore: viewStore
        )
    }

    private func getUserConnectionScrollFeed(
        getFeedRequest: GetFeedRequest,
        viewStore: ViewStore<ContentScrollViewReducer<UserConnectionView>.State, ContentScrollViewReducer<UserConnectionView>.Action>
    ) -> PostStream<UserConnectionView> {
        return PostStream(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest,
            viewStore: viewStore
        )
    }

    func getFollowingScrollFeed(
        userId: UUID,
        viewStore: ViewStore<ContentScrollViewReducer<UserConnectionView>.State, ContentScrollViewReducer<UserConnectionView>.Action>
    ) -> PostStream<UserConnectionView> {
        getUserConnectionScrollFeed(
            getFeedRequest: GetFeedRequest.with {
                $0.loginSession = loginSession.toProto()
                $0.getFollowingFeedRequest = GetFeedRequest.GetFollowingFeedRequest.with {
                    $0.userID = userId.uuidString
                }
            },
            viewStore: viewStore
        )
    }

    func getFollowersScrollFeed(
        userId: UUID,
        viewStore: ViewStore<ContentScrollViewReducer<UserConnectionView>.State, ContentScrollViewReducer<UserConnectionView>.Action>
    ) -> PostStream<UserConnectionView> {
        getUserConnectionScrollFeed(
            getFeedRequest:
            GetFeedRequest.with {
                $0.loginSession = loginSession.toProto()
                $0.getFollowersFeedRequest = GetFeedRequest.GetFollowersFeedRequest.with {
                    $0.userID = userId.uuidString
                }
            },
            viewStore: viewStore
        )
    }
}
