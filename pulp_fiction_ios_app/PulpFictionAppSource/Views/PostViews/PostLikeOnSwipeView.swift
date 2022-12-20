//
// Functionality for liking a post via swiping
//
//  SwipablePostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/13/22.
//

import Bow
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

typealias PostLikeOnSwipeReducer = SwipablePostViewReducer<PostLikeArrowReducer>

/// Reducer for updating the post like arrow
struct PostLikeArrowReducer: ReducerProtocol {
    let backendMessenger: BackendMessenger
    let postMetadata: PostMetadata
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    private let logger = Logger(label: String(describing: PostLikeArrowReducer.self))

    struct State: Equatable {
        /// Whether or not the current logged in user likes the current post or not
        var loggedInUserPostLikeStatus: Post.PostLike
        /// Total # of likes - dislikes for the current post
        var postNumNetLikes: Int64
        var showErrorCommunicatingWithServerAlert: Bool = false
    }

    indirect enum Action: Equatable {
        case updatePostLikeStatus(PostLikeOnSwipeReducer.Action)
        case processUpdatePostLikeStatusResponseFromBackend((Post.PostLike, Int64), Either<PulpFictionRequestError, UpdatePostResponse>)
        case tapPostLikeArrow
        case updateShowErrorCommunicatingWithServerAlert(Bool)

        static func == (lhs: PostLikeArrowReducer.Action, rhs: PostLikeArrowReducer.Action) -> Bool {
            switch (lhs, rhs) {
            case let (.updatePostLikeStatus(leftSwipablePostAction), .updatePostLikeStatus(rightSwipablePostAction)):
                return leftSwipablePostAction == rightSwipablePostAction
            case let (.processUpdatePostLikeStatusResponseFromBackend(leftPostLikeUpdate, leftUpdatePostResponseEither), .processUpdatePostLikeStatusResponseFromBackend(rightPostLikeUpdate, rightUpdatePostResponseEither)):
                return leftPostLikeUpdate == rightPostLikeUpdate &&
                    leftUpdatePostResponseEither == rightUpdatePostResponseEither
            case (.tapPostLikeArrow, .tapPostLikeArrow):
                return true
            case let (.updateShowErrorCommunicatingWithServerAlert(leftNewShowErrorCommunicatingWithServerAlert), .updateShowErrorCommunicatingWithServerAlert(rightNewShowErrorCommunicatingWithServerAlert)):
                return leftNewShowErrorCommunicatingWithServerAlert == rightNewShowErrorCommunicatingWithServerAlert
            default:
                return false
            }
        }
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .tapPostLikeArrow:
            return .task { .updatePostLikeStatus(.swipeLeft) }

        case let .updatePostLikeStatus(swipablePostAction):
            let postLikeUpdateMaybe: (Post.PostLike, Int64)? = {
                switch (state.loggedInUserPostLikeStatus, swipablePostAction) {
                case (.neutral, .swipeLeft):
                    return (.like, 1)
                case (.neutral, .swipeRight):
                    return (.dislike, -1)
                case (.like, .swipeLeft):
                    return (.neutral, -1)
                case (.dislike, .swipeRight):
                    return (.neutral, 1)
                case (.dislike, .swipeLeft):
                    return (.like, 1)
                case (.like, .swipeRight):
                    return (.dislike, -2)
                default:
                    return nil
                }
            }()

            logger.debug(
                "Updating loggedInUserPostLikeStatus.",
                metadata: [
                    "swipablePostAction": "\(swipablePostAction)",
                    "postLikeUpdateMaybe": "\(String(describing: postLikeUpdateMaybe))",
                ]
            )

            if let postLikeUpdate = postLikeUpdateMaybe {
                return .task {
                    let updatePostResponseEither = await backendMessenger
                        .updatePostBackendMessenger
                        .updatePostLikeStatus(
                            postId: postMetadata.postUpdateIdentifier.postId,
                            newPostLikeStatus: postLikeUpdate.0
                        )

                    return .processUpdatePostLikeStatusResponseFromBackend(postLikeUpdate, updatePostResponseEither)
                }
            } else {
                logger.error("Unrecognized action",
                             metadata: [
                                 "postLikeStatus": "\(state.loggedInUserPostLikeStatus)",
                                 "swipablePostAction": "\(swipablePostAction)",
                             ])
                return .none
            }

        case let .processUpdatePostLikeStatusResponseFromBackend(postLikeUpdate, updatePostResponseEither):
            switch updatePostResponseEither.toEnum() {
            case let .left(error):
                logger.error("Error communicating with backend server",
                             metadata: [
                                 "error": "\(error)",
                                 "cause": "\(String(describing: error.causeMaybe.orNil))",
                             ])

                notificationBannerViewStore.send(.showNotificationBanner("Error contacting server. Please try again later.", .error))
                return .none
            case .right:
                state.loggedInUserPostLikeStatus = postLikeUpdate.0
                state.postNumNetLikes += postLikeUpdate.1

                logger.debug(
                    "Successfully processed UpdatePostResponse from backed",
                    metadata: [
                        "postLikeUpdate": "\(postLikeUpdate)",
                        "updatePostResponseEither": "\(String(describing: updatePostResponseEither))",
                    ]
                )

                return .none
            }

        case let .updateShowErrorCommunicatingWithServerAlert(newShowErrorCommunicatingWithServerAlert):
            state.showErrorCommunicatingWithServerAlert = newShowErrorCommunicatingWithServerAlert
            return .none
        }
    }
}

/// View that generates an arrow which shows info about likes for a post
struct PostLikeArrowView: View {
    private let store: ComposableArchitecture.StoreOf<PostLikeArrowReducer>
    fileprivate init(store: ComposableArchitecture.StoreOf<PostLikeArrowReducer>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            buildPostLikeArrow(viewStore.state)
                .onTapGesture { viewStore.send(.tapPostLikeArrow) }
//            .alert("Error contacting server. Please try again later.", isPresented: viewStore.binding(
//                get: \.showErrorCommunicatingWithServerAlert,
//                send: .updateShowErrorCommunicatingWithServerAlert(false))) {
//                    Button("OK", role: .cancel) {}
//            }
        }
    }

    private func buildPostLikeArrow(_ state: PostLikeArrowReducer.State) -> some View {
        switch state.loggedInUserPostLikeStatus {
        case .neutral, .UNRECOGNIZED:
            return SymbolWithCaption(
                symbolName: "arrow.up",
                symbolCaption: state.postNumNetLikes.formatAsStringForView()
            )
        case .like:
            return SymbolWithCaption(
                symbolName: "arrow.up",
                symbolCaption: state.postNumNetLikes.formatAsStringForView(),
                color: .orange
            )
        case .dislike:
            return SymbolWithCaption(
                symbolName: "arrow.down",
                symbolCaption: state.postNumNetLikes.formatAsStringForView(),
                color: .blue
            )
        }
    }
}

/// All posts that introduce like on swipe functionality implement this protocol
protocol PostLikeOnSwipeView: ScrollableContentView {
    var swipablePostStore: ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer> { get }
    associatedtype Content: View
    var body: SwipableContentView<Content, PostLikeArrowReducer> { get }

    /// Build a PostLikeArrowView
    func buildPostLikeArrowView() -> PostLikeArrowView

    /// Buils the view for which post swipe functionality is wrapped around
    @ViewBuilder func postViewBuilder() -> Content
}

extension PostLikeOnSwipeView {
    public var body: SwipableContentView<Content, PostLikeArrowReducer> {
        SwipableContentView(
            store: swipablePostStore,
            swipeLeftSymbolName: "arrow.up",
            swipeRightSymbolName: "arrow.down",
            postViewBuilder: postViewBuilder
        )
    }

    func buildPostLikeArrowView() -> PostLikeArrowView {
        PostLikeArrowView(
            store: swipablePostStore.scope(
                state: { $0.viewComponentsState },
                action: { postLikeArrowReducerAction in .updateViewComponents(postLikeArrowReducerAction) }
            )
        )
    }

    static func buildStore(
        backendMessenger: BackendMessenger,
        postMetadata: PostMetadata,
        postInteractionAggregates: PostInteractionAggregates,
        loggedInUserPostInteractions: LoggedInUserPostInteractions,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer> {
        Store(
            initialState: PostLikeOnSwipeReducer.State(
                viewComponentsState: PostLikeArrowReducer.State(
                    loggedInUserPostLikeStatus: loggedInUserPostInteractions.postLikeStatus,
                    postNumNetLikes: postInteractionAggregates.getNetLikes()
                )
            ),
            reducer: PostLikeOnSwipeReducer(
                viewComponentsReducerSuplier: { PostLikeArrowReducer(
                    backendMessenger: backendMessenger,
                    postMetadata: postMetadata,
                    notificationBannerViewStore: notificationBannerViewStore
                ) },
                updateViewComponentsActionSupplier: { _, dragOffset in
                    if (dragOffset.width + 1e-6) < 0 {
                        return .updatePostLikeStatus(.swipeLeft)
                    } else if (dragOffset.width - 1e-6) > 0 {
                        return .updatePostLikeStatus(.swipeRight)
                    } else {
                        return nil
                    }
                }
            )
        )
    }
}
