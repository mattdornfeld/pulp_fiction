//
//  CommentView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/9/22.
//

import Bow
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

private struct CommentViewReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadUserProfileView: Bool = false
    }

    enum Action {
        case updateShouldLoadUserProfileView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadUserProfileView(shouldLoadUserProfileView):
            state.shouldLoadUserProfileView = shouldLoadUserProfileView
            return .none
        }
    }
}

struct CommentView: PostLikeOnSwipeView {
    let commentPostData: CommentPostData
    let creatorUserPostData: UserPostData
    let id: Int
    let postFeedMessenger: PostFeedMessenger
    let loggedInUserPostData: UserPostData
    let backendMessenger: BackendMessenger
    private static let logger = Logger(label: String(describing: CommentView.self))
    internal let swipablePostStore: ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer>
    private let store: ComposableArchitecture.StoreOf<CommentViewReducer>
    private let notificationBannerViewStore: NotificationnotificationBannerViewStore

    init(
        commentPostData: CommentPostData,
        creatorUserPostData: UserPostData,
        id: Int,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.commentPostData = commentPostData
        self.creatorUserPostData = creatorUserPostData
        self.id = id
        self.postFeedMessenger = postFeedMessenger
        self.loggedInUserPostData = loggedInUserPostData
        self.backendMessenger = backendMessenger
        self.notificationBannerViewStore = notificationBannerViewStore
        swipablePostStore = CommentView.buildStore(
            backendMessenger: backendMessenger,
            postMetadata: commentPostData.postMetadata,
            postInteractionAggregates: commentPostData.postInteractionAggregates,
            loggedInUserPostInteractions: commentPostData.loggedInUserPostInteractions,
            notificationBannerViewStore: notificationBannerViewStore
        )
        store = Store(
            initialState: CommentViewReducer.State(),
            reducer: CommentViewReducer()
        )
    }

    static func == (lhs: CommentView, rhs: CommentView) -> Bool {
        lhs.commentPostData == rhs.commentPostData
            && lhs.creatorUserPostData == rhs.creatorUserPostData
            && lhs.id == rhs.id
    }

    @ViewBuilder func postViewBuilder() -> some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading) {
                HStack(alignment: .bottom, spacing: 5) {
                    BoldCaption(creatorUserPostData.userDisplayName)
                        .foregroundColor(.black)
                        .navigateOnTap(
                            isActive: viewStore.binding(
                                get: \.shouldLoadUserProfileView,
                                send: CommentViewReducer.Action.updateShouldLoadUserProfileView(false)
                            ),
                            destination: UserProfileView(
                                userProfileOwnerPostData: creatorUserPostData,
                                loggedInUserPostData: loggedInUserPostData,
                                postFeedMessenger: postFeedMessenger,
                                backendMessenger: backendMessenger,
                                notificationBannerViewStore: notificationBannerViewStore
                            )
                        ) { viewStore.send(.updateShouldLoadUserProfileView(true)) }
                    buildPostLikeArrowView()
                    Spacer()
                    Caption(
                        text: commentPostData.postMetadata.createdAt.formatAsStringForView(),
                        color: .gray
                    )
                    ExtraOptionsDropDownMenuView(
                        postMetadata: commentPostData.postMetadata,
                        backendMessenger: backendMessenger,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                }
                Caption(commentPostData.body)
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
        }
    }

    static func create(
        postViewIndex: Int,
        commentPostData: CommentPostData,
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> Either<PulpFictionRequestError, CommentView> {
        return binding(
            yield: CommentView(
                commentPostData: commentPostData,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                loggedInUserPostData: loggedInUserPostData,
                notificationBannerViewStore: notificationBannerViewStore
            )
        )^.onError { cause in
            logger.error(
                "Error loading comment \(commentPostData.postMetadata.postUpdateIdentifier)",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
    }
}
