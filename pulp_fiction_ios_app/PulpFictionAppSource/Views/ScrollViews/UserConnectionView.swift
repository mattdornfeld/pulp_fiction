//
//  UserConnectionView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/22/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for updating UserConnectionView
struct UserConnectionViewReducer: ReducerProtocol {
    let userPostData: UserPostData
    let backendMessenger: BackendMessenger
    let notificationnotificationBannerViewStore: NotificationnotificationBannerViewStore

    struct State: Equatable {
        /// Boolean that shows whether or not the current user following the user connection
        var userFollowingStatus: UserFollowingStatus = .notFollowing
        var followingOpacity: CGFloat {
            switch userFollowingStatus {
            case .following:
                return 1.0
            default:
                return 0.0
            }
        }

        var notFollowingOpacity: CGFloat {
            switch userFollowingStatus {
            case .following:
                return 0.0
            default:
                return 1.0
            }
        }

        var backgroundColor: Color {
            switch userFollowingStatus {
            case .following:
                return .orange
            default:
                return .blue
            }
        }
    }

    enum Action: Equatable {
        /// Updates the following status of a user connection
        case updateUserFollowingStatus(UserFollowingStatus)
        case processUpdateUserResponse(Either<PulpFictionRequestError, UpdateUserResponse>, UserFollowingStatus)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateUserFollowingStatus(newUserFollowingStatus):
            return .task {
                let updateUserResponseEither = await backendMessenger
                    .updateUserBackendMessenger
                    .updateUserFollowingStatus(
                        targetUserId: userPostData.userId,
                        newUserFollowingStatus: newUserFollowingStatus
                    )
                return .processUpdateUserResponse(updateUserResponseEither, newUserFollowingStatus)
            }

        case let .processUpdateUserResponse(updateUserResponseEither, newUserFollowingStatus):
            updateUserResponseEither.processResponseFromServer(
                notificationBannerViewStore: notificationnotificationBannerViewStore,
                state: state,
                path: "updateUserFollowingStatus"
            ).onSuccess { _ in
                state.userFollowingStatus = newUserFollowingStatus
                switch newUserFollowingStatus {
                case .following:
                    notificationnotificationBannerViewStore.send(.showNotificationBanner("User followed!", .success))
                default:
                    notificationnotificationBannerViewStore.send(.showNotificationBanner("User unfollowed", .info))
                }
            }
            return .none
        }
    }
}

/// Constructs a view that shows a users connection with another user (e.g. a follower or a followee)
struct UserConnectionView: ScrollableContentView {
    let id: Int
    let userPostData: UserPostData
    let externalMessengers: ExternalMessengers
    let loggedInUserPostData: UserPostData
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    var postMetadata: PostMetadata { userPostData.postMetadata }
    private var store: ComposableArchitecture.StoreOf<SwipablePostViewReducer<UserConnectionViewReducer>> {
        Store(
            initialState: SwipablePostViewReducer.State(viewComponentsState: UserConnectionViewReducer.State()),
            reducer: SwipablePostViewReducer(
                viewComponentsReducerSuplier: { UserConnectionViewReducer(
                    userPostData: userPostData,
                    backendMessenger: backendMessenger,
                    notificationnotificationBannerViewStore: notificationBannerViewStore
                ) },
                updateViewComponentsActionSupplier: { _, dragOffset in
                    if (dragOffset.width + 1e-6) < 0 {
                        return .updateUserFollowingStatus(.following)
                    } else if (dragOffset.width - 1e-6) > 0 {
                        return .updateUserFollowingStatus(.notFollowing)
                    } else {
                        return nil
                    }
                }
            )
        )
    }

    static func == (lhs: UserConnectionView, rhs: UserConnectionView) -> Bool {
        lhs.id == rhs.id
            && lhs.userPostData == rhs.userPostData
    }

    var body: some View {
        let _store = store
        WithViewStore(_store) { viewStore in
            SwipableContentView(
                store: _store,
                swipeLeftSymbolName: "figure.stand.line.dotted.figure.stand",
                swipeRightSymbolName: "figure.dress.line.vertical.figure"
            ) {
                HStack {
                    UserPostView(
                        userPostData: userPostData,
                        externalMessengers: externalMessengers,
                        loggedInUserPostData: loggedInUserPostData,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                    Spacer()
                    buildFollowingNotFolowingCaption(viewStore.state.viewComponentsState)
                }
            }
        }
    }

    @ViewBuilder func buildFollowingNotFolowingCaption(_ state: UserConnectionViewReducer.State) -> some View {
        ZStack {
            Caption(
                text: "Following",
                color: .white
            )
            .padding()
            .opacity(state.followingOpacity)
            Caption(
                text: "Not Following",
                color: .white
            )
            .padding()
            .opacity(state.notFollowingOpacity)
        }.background(state.backgroundColor)
    }

    static func getPostViewEitherSupplier(
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> PostViewEitherSupplier<UserConnectionView> {
        { postViewIndex, postProto, _ in
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()

            return binding(
                userPostDataEither <- externalMessengers.postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                yield: UserConnectionView(
                    id: postViewIndex,
                    userPostData: userPostDataEither.get,
                    externalMessengers: externalMessengers,
                    loggedInUserPostData: externalMessengers.postFeedMessenger.loginSession.loggedInUserPostData,
                    notificationBannerViewStore: notificationBannerViewStore
                )
            )^
        }
    }
}
