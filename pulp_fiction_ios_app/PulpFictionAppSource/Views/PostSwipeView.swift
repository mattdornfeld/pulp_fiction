//
// Functionality for interacting with a post via swiping
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

struct PostLikeArrowReducer: ReducerProtocol {
    struct State: Equatable {
        /// Whether or not the current logged in user likes the current post or not
        var loggedInUserPostLikeStatus: Post.PostLike
        /// Total # of likes - dislikes for the current post
        var postNumNetLikes: Int64
    }

    indirect enum Action {
        case updatePostLikeStatus(PostSwipeViewReducer.Action)
        case tapPostLikeArrow
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .tapPostLikeArrow:
            return .task { .updatePostLikeStatus(.like) }

        case let .updatePostLikeStatus(swipablePostAction):
            switch (state.loggedInUserPostLikeStatus, swipablePostAction) {
            case (.neutral, .like):
                state.loggedInUserPostLikeStatus = .like
                state.postNumNetLikes += 1
            case (.neutral, .dislike):
                state.loggedInUserPostLikeStatus = .dislike
                state.postNumNetLikes -= 1
            case (.like, .like):
                state.loggedInUserPostLikeStatus = .neutral
                state.postNumNetLikes -= 1
            case (.dislike, .dislike):
                state.loggedInUserPostLikeStatus = .neutral
                state.postNumNetLikes += 1
            case (.dislike, .like):
                state.loggedInUserPostLikeStatus = .like
                state.postNumNetLikes += 2
            case (.like, .dislike):
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

struct PostSwipeViewReducer: ReducerProtocol {
    struct State: Equatable {
        /// The offset of the post from its initial position. Keeps track of how far the post has been dragged
        fileprivate var dragOffset: CGSize = .zero
        /// The visibility of the parts of the view that signify a post is being liked
        fileprivate var likeOpacity: CGFloat = 0.0
        /// The visibility of the part of the view that signify a post is being disliked
        fileprivate var dislikeOpacity: CGFloat = 0.0
        /// State of the PostLikeArrowView
        fileprivate var postLikeArrowState: PostLikeArrowReducer.State
    }

    enum Action {
        /// Called when post is being moved via a swipe
        case translate(CGSize)
        /// Called when post is moved back to neutral position
        case neutral
        /// Called when post is swiped to the like position
        case like
        /// Called when post is swiped to the dislike position
        case dislike
        /// Called when a swipe gesture is ended
        case endSwipeGesture(CGSize)
        /// Calls the postLikeArrowReducer
        case updatePostLikeArrow(PostLikeArrowReducer.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.postLikeArrowState, action: /Action.updatePostLikeArrow) {
            PostLikeArrowReducer()
        }

        Reduce { state, action in
            switch action {
            case let .translate(dragOffset):
                state.dragOffset = dragOffset

                if (dragOffset.width + 1e-6) < 0 {
                    return .task { .like }
                } else if (dragOffset.width - 1e-6) > 0 {
                    return .task { .dislike }
                } else {
                    return .task { .neutral }
                }

            case .neutral:
                state.likeOpacity = 0.0
                state.dislikeOpacity = 0.0
                return .none

            case .like:
                state.likeOpacity = 1.0
                state.dislikeOpacity = 0.0
                return .none

            case .dislike:
                state.likeOpacity = 0.0
                state.dislikeOpacity = 1.0
                return .none

            case let .endSwipeGesture(dragOffset):
                if (dragOffset.width + 1e-6) < 0 {
                    return .task { .updatePostLikeArrow(.updatePostLikeStatus(.like)) }
                } else if (dragOffset.width - 1e-6) > 0 {
                    return .task { .updatePostLikeArrow(.updatePostLikeStatus(.dislike)) }
                } else {
                    return .task { .translate(CGSize.zero) }
                }

            case .updatePostLikeArrow:
                return .task { .translate(CGSize.zero) }
            }
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

/// A wrapper view that introduces functionality for interacting with a post via swiping
struct PostSwipeView<Content: View>: View {
    private let store: ComposableArchitecture.StoreOf<PostSwipeViewReducer>
    private let postView: Content

    fileprivate init(
        postViewBuilder: @escaping () -> Content,
        store: ComposableArchitecture.StoreOf<PostSwipeViewReducer>
    ) {
        self.store = store
        postView = postViewBuilder()
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.orange.opacity(viewStore.state.likeOpacity)
                Color.blue.opacity(viewStore.state.dislikeOpacity)
                postView
                    .background(Color.white)
                    .offset(x: viewStore.state.dragOffset.width, y: 0)
                    .gesture(DragGesture()
                        .onChanged { value in
                            viewStore.send(.translate(value.translation))
                        }
                        .onEnded { value in
                            viewStore.send(.endSwipeGesture(value.translation))
                        })
                    .overlay(alignment: .trailing) {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(Color.white)
                            .opacity(viewStore.state.likeOpacity)
                    }
                    .overlay(alignment: .leading) {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(Color.white)
                            .opacity(viewStore.state.dislikeOpacity)
                    }
            }
        }
    }
}

/// All posts that introduce swipe functionality implement this protocol
protocol SwipablePostView: ScrollableContentView {
    var swipablePostStore: ComposableArchitecture.StoreOf<PostSwipeViewReducer> { get }
    associatedtype Content: View
    var body: PostSwipeView<Content> { get }

    /// Build a PostLikeArrowView
    func buildPostLikeArrowView() -> PostLikeArrowView

    /// Buils the view for which post swipe functionality is wrapped around
    @ViewBuilder func postViewBuilder() -> Content
}

extension SwipablePostView {
    public var body: PostSwipeView<Content> {
        PostSwipeView(
            postViewBuilder: postViewBuilder,
            store: swipablePostStore
        )
    }

    func buildPostLikeArrowView() -> PostLikeArrowView {
        PostLikeArrowView(
            store: swipablePostStore.scope(
                state: { $0.postLikeArrowState },
                action: { PostLikeArrowReducerAction in .updatePostLikeArrow(PostLikeArrowReducerAction) }
            )
        )
    }

    static func buildStore(
        postInteractionAggregates: PostInteractionAggregates,
        loggedInUserPostInteractions: LoggedInUserPostInteractions
    ) -> ComposableArchitecture.StoreOf<PostSwipeViewReducer> {
        Store(
            initialState: PostSwipeViewReducer.State(
                postLikeArrowState: PostLikeArrowReducer.State(
                    loggedInUserPostLikeStatus: loggedInUserPostInteractions.postLikeStatus,
                    postNumNetLikes: postInteractionAggregates.getNetLikes()
                )
            ),
            reducer: PostSwipeViewReducer()
        )
    }
}
