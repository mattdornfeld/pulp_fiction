//
// Functionality for liking a post via swiping
//
//  SwipablePostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/13/22.
//

import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

private let logger = Logger(label: String(describing: "PostSwipeView"))

typealias PostLikeOnSwipeReducer = SwipablePostViewReducer<PostLikeArrowReducer>

/// Reducer for updating the post like arrow
struct PostLikeArrowReducer: ReducerProtocol {
    struct State: Equatable {
        /// Whether or not the current logged in user likes the current post or not
        var loggedInUserPostLikeStatus: Post.PostLike
        /// Total # of likes - dislikes for the current post
        var postNumNetLikes: Int64
    }

    indirect enum Action {
        case updatePostLikeStatus(PostLikeOnSwipeReducer.Action)
        case tapPostLikeArrow
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .tapPostLikeArrow:
            return .task { .updatePostLikeStatus(.swipeLeft) }

        case let .updatePostLikeStatus(swipablePostAction):
            switch (state.loggedInUserPostLikeStatus, swipablePostAction) {
            case (.neutral, .swipeLeft):
                state.loggedInUserPostLikeStatus = .like
                state.postNumNetLikes += 1
            case (.neutral, .swipeRight):
                state.loggedInUserPostLikeStatus = .dislike
                state.postNumNetLikes -= 1
            case (.like, .swipeLeft):
                state.loggedInUserPostLikeStatus = .neutral
                state.postNumNetLikes -= 1
            case (.dislike, .swipeRight):
                state.loggedInUserPostLikeStatus = .neutral
                state.postNumNetLikes += 1
            case (.dislike, .swipeLeft):
                state.loggedInUserPostLikeStatus = .like
                state.postNumNetLikes += 2
            case (.like, .swipeRight):
                state.loggedInUserPostLikeStatus = .dislike
                state.postNumNetLikes -= 2
            default:
                logger.error("Unrecognized action",
                             metadata: [
                                 "postLikeStatus": "\(state.loggedInUserPostLikeStatus)",
                                 "swipablePostAction": "\(swipablePostAction)",
                             ])
            }

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
        postInteractionAggregates: PostInteractionAggregates,
        loggedInUserPostInteractions: LoggedInUserPostInteractions
    ) -> ComposableArchitecture.StoreOf<PostLikeOnSwipeReducer> {
        Store(
            initialState: PostLikeOnSwipeReducer.State(
                viewComponentsState: PostLikeArrowReducer.State(
                    loggedInUserPostLikeStatus: loggedInUserPostInteractions.postLikeStatus,
                    postNumNetLikes: postInteractionAggregates.getNetLikes()
                )
            ),
            reducer: PostLikeOnSwipeReducer(
                viewComponentsReducerSuplier: { PostLikeArrowReducer() },
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
