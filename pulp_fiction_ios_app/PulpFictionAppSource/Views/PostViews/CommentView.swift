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
    let externalMessengers: ExternalMessengers
    let loggedInUserPostData: UserPostData
    let contentScrollViewStore: ContentScrollViewStore<CommentView>
    var postMetadata: PostMetadata { commentPostData.postMetadata }
    private static let logger = Logger(label: String(describing: CommentView.self))
    internal let swipablePostStore: ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer>
    private let store: ComposableArchitecture.StoreOf<CommentViewReducer>
    private let notificationBannerViewStore: NotificationnotificationBannerViewStore

    init(
        commentPostData: CommentPostData,
        creatorUserPostData: UserPostData,
        id: Int,
        externalMessengers: ExternalMessengers,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        contentScrollViewStore: ContentScrollViewStore<CommentView>
    ) {
        self.commentPostData = commentPostData
        self.creatorUserPostData = creatorUserPostData
        self.id = id
        self.externalMessengers = externalMessengers
        self.loggedInUserPostData = loggedInUserPostData
        self.notificationBannerViewStore = notificationBannerViewStore
        self.contentScrollViewStore = contentScrollViewStore
        swipablePostStore = CommentView.buildStore(
            externalMessengers: externalMessengers,
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
                                externalMessengers: externalMessengers,
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
                        externalMessengers: externalMessengers,
                        notificationBannerViewStore: notificationBannerViewStore,
                        contentScrollViewStore: contentScrollViewStore
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
        externalMessengers: ExternalMessengers,
        loggedInUserPostData: UserPostData,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        contentScrollViewStore: ContentScrollViewStore<CommentView>
    ) -> Either<PulpFictionRequestError, CommentView> {
        return binding(
            yield: CommentView(
                commentPostData: commentPostData,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                externalMessengers: externalMessengers,
                loggedInUserPostData: loggedInUserPostData,
                notificationBannerViewStore: notificationBannerViewStore,
                contentScrollViewStore: contentScrollViewStore
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

    static func getPostViewEitherSupplier(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> PostViewEitherSupplier<CommentView> {
        { postViewIndex, postProto, contentScrollViewStore in
            let commentPostDataEither = Either<PulpFictionRequestError, CommentPostData>.var()
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
            let commentViewEither = Either<PulpFictionRequestError, CommentView>.var()

            return binding(
                commentPostDataEither <- externalMessengers.postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toCommentPostData() }^,
                userPostDataEither <- externalMessengers.postDataMessenger
                    .getPostData(postProto.comment.postCreatorLatestUserPost)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                commentViewEither <- CommentView.create(
                    postViewIndex: postViewIndex,
                    commentPostData: commentPostDataEither.get,
                    userPostData: userPostDataEither.get,
                    externalMessengers: externalMessengers,
                    loggedInUserPostData: externalMessengers.postFeedMessenger.loginSession.loggedInUserPostData,
                    notificationBannerViewStore: notificationBannerViewStore,
                    contentScrollViewStore: contentScrollViewStore
                ),
                yield: commentViewEither.get
            )^
        }
    }
}
