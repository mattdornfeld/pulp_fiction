//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import ComposableArchitecture
import Logging
import SwiftUI

private typealias ScrollPostViews = [ImagePostView]

private struct PostScrollState: Equatable {
    private enum Companion {
        static let logger: Logger = .init(label: String(describing: PostScrollState.self))
    }

    /// The iterator used to retrieve posts from the backend API and data store
    var postViewFeedIteratorMaybe: PostViewFeedIterator? = nil
    /// The PostView objects currently available in the scroll
    var postViews: ScrollPostViews = []
    var feedLoadProgressIndicatorOpacity: Double = 0.0

    func shouldLoadMorePosts(_ postViewFeedIterator: PostViewFeedIterator, _ currentPostViewIndex: Int) -> Bool {
        let thresholdIndex = postViews.index(postViews.endIndex, offsetBy: -PostFeedConfigs.numPostViewsLoadedInAdvance)
        return !postViewFeedIterator.isDone
            && (postViews.count == 0
                || postViews.firstIndex(where: { $0.id == currentPostViewIndex }) == thresholdIndex
            )
    }

    mutating func loadMorePostsIfNeeded(_ postViewFeedIterator: PostViewFeedIterator, _ currentPostViewIndex: Int) {
        if shouldLoadMorePosts(postViewFeedIterator, currentPostViewIndex) {
            Companion.logger.debug(
                "Loading more posts from iterator",
                metadata: [
                    "currentPostViewIndex": "\(currentPostViewIndex)",
                    "numPostsInScroll": "\(postViews.count)",
                ]
            )

            (1 ... PostFeedConfigs.numPostViewsLoadedInAdvance).forEach { _ in
                postViewFeedIterator.next().map { postView in
                    self.postViews.append(postView)
                }
            }
        } else {
            Companion.logger.debug(
                "Loading more posts from iterator is not needed. Continuing",
                metadata: [
                    "currentPostViewIndex": "\(currentPostViewIndex)",
                    "numPostsInScroll": "\(postViews.count)",
                ]
            )
        }
    }
}

private struct PostScrollEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let postFeedMessenger: PostFeedMessenger
}

private enum PostScrollAction {
    /// This action is called on view load. It starts the PostViewFeedIterator and begins loading posts into the view.
    case startScroll
    case refreshScroll
    /// Loads more posts if necessary. Triggered on scroll.
    case loadMorePostsIfNeeded(ImagePostView)
    /// Handles errors with loadMorePostsIfNeeded.
    case loadMorePostsIfNeededHandleErrors(Result<Void, PulpFictionRequestError>)
}

private enum PostScrollErrors {
    class PostViewFeedIteratorNotStarted: PulpFictionRequestError {}
}

private enum PostScrollReducer {
    private static let logger: Logger = .init(label: String(describing: PostCreatorReducer.self))
    static let reducer: Reducer<PostScrollState, PostScrollAction, PostScrollEnvironment> = Reducer<PostScrollState, PostScrollAction, PostScrollEnvironment> {
        state, action, environment in
        switch action {
        case .startScroll:
            state.postViews = []
            state.postViewFeedIteratorMaybe = {
                let postViewFeedIterator = environment
                    .postFeedMessenger
                    .getGlobalPostFeed()
                    .makeIterator()

                logger.debug("Started post feed iterator")

                state.loadMorePostsIfNeeded(postViewFeedIterator, 0)

                return postViewFeedIterator
            }()
            state.feedLoadProgressIndicatorOpacity = 0.0
            return .none

        case .refreshScroll:
            state.feedLoadProgressIndicatorOpacity = 1.0
            return .task {
                .startScroll
            }

        case let .loadMorePostsIfNeeded(currentPostView):
            return state.postViewFeedIteratorMaybe.map { postViewFeedIterator in
                state.loadMorePostsIfNeeded(postViewFeedIterator, currentPostView.id)
            }
            .toEither(PostScrollErrors.PostViewFeedIteratorNotStarted())
            .toEffect()
            .receive(on: environment.mainQueue)
            .catchToEffect(PostScrollAction.loadMorePostsIfNeededHandleErrors)

        case .loadMorePostsIfNeededHandleErrors(.success):
            return .none

        case let .loadMorePostsIfNeededHandleErrors(.failure(cause)):
            logger.error(
                "Error loading posts",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
            return .none
        }
    }
}

public struct PostScrollView: View {
    private let store: Store<PostScrollState, PostScrollAction>
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    @GestureState private var dragOffset: CGFloat = -100

    public init(postFeedMessenger: PostFeedMessenger) {
        store = Store(
            initialState: PostScrollState(),
            reducer: PostScrollReducer.reducer,
            environment: PostScrollEnvironment(
                mainQueue: .main,
                postFeedMessenger: postFeedMessenger
            )
        )
    }

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            ScrollView {
                VStack(alignment: .center) {
                    ProgressView()
                        .scaleEffect(progressIndicatorScaleFactor, anchor: .center)
                        .opacity(viewStore.state.feedLoadProgressIndicatorOpacity)

                    LazyVStack(alignment: .leading) {
                        ForEach(viewStore.state.postViews) { currentPost in
                            currentPost.onAppear {
                                viewStore.send(.loadMorePostsIfNeeded(currentPost))
                            }
                        }
                    }

                    Caption("You have reached the end\nTry refreshing the feed to see new posts")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .onAppear { viewStore.send(.startScroll) }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, gestureState, _ in
                        let delta = value.location.y - value.startLocation.y
                        if delta > refreshFeedOnScrollUpSensitivity {
                            gestureState = delta
                            viewStore.send(.refreshScroll)
                        }
                    }
            )
        }
    }
}
