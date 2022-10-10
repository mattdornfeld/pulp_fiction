//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import ComposableArchitecture
import Logging
import SwiftUI

fileprivate let logger: Logger = .init(label: String(describing: "PostScrollView"))

fileprivate struct PostScrollState<A: PostView>: Equatable {
    /// The iterator used to retrieve posts from the backend API and data store
    var postViewFeedIteratorMaybe: PostViewFeedIterator<A>? = nil
    /// The PostView objects currently available in the scroll
    var postViews: [A] = []
    var feedLoadProgressIndicatorOpacity: Double = 0.0

    func shouldLoadMorePosts(_ postViewFeedIterator: PostViewFeedIterator<A>, _ currentPostViewIndex: Int) -> Bool {
        let thresholdIndex = postViews.index(postViews.endIndex, offsetBy: -PostFeedConfigs.numPostViewsLoadedInAdvance)
        return !postViewFeedIterator.isDone
            && (postViews.count == 0
                || postViews.firstIndex(where: { $0.id == currentPostViewIndex }) == thresholdIndex
            )
    }

    mutating func loadMorePostsIfNeeded(_ postViewFeedIterator: PostViewFeedIterator<A>, _ currentPostViewIndex: Int) {
        if shouldLoadMorePosts(postViewFeedIterator, currentPostViewIndex) {
            logger.debug(
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
            logger.debug(
                "Loading more posts from iterator is not needed. Continuing",
                metadata: [
                    "currentPostViewIndex": "\(currentPostViewIndex)",
                    "numPostsInScroll": "\(postViews.count)",
                ]
            )
        }
    }
}

fileprivate struct PostScrollEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let postFeedMessenger: PostFeedMessenger
}

fileprivate enum PostScrollAction {
    /// This action is called on view load. It starts the PostViewFeedIterator and begins loading posts into the view.
    case startScroll
    case refreshScroll
    /// Loads more posts if necessary. Triggered on scroll.
    case loadMorePostsIfNeeded(any PostView)
    /// Handles errors with loadMorePostsIfNeeded.
    case loadMorePostsIfNeededHandleErrors(Result<Void, PulpFictionRequestError>)
}

fileprivate enum PostScrollErrors {
    class PostViewFeedIteratorNotStarted: PulpFictionRequestError {}
}

fileprivate struct PostScrollReducer<A: PostView> {
    let postViewFeedIteratorSupplier: (PostScrollEnvironment) -> PostViewFeedIterator<A>

    func buildReducer() -> Reducer<PostScrollState<A>, PostScrollAction, PostScrollEnvironment> {
        Reducer<PostScrollState<A>, PostScrollAction, PostScrollEnvironment> {
            state, action, environment in
            switch action {
            case .startScroll:
                state.postViews = []
                state.postViewFeedIteratorMaybe = {
                    let postViewFeedIterator = postViewFeedIteratorSupplier(environment)

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
}

fileprivate struct PostScrollViewBuilder<A: PostView> {
    private let store: Store<PostScrollState<A>, PostScrollAction>
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    @GestureState private var dragOffset: CGFloat = -100

    init(
        postFeedMessenger: PostFeedMessenger,
        postViewFeedIteratorSupplier: @escaping (PostScrollEnvironment) -> PostViewFeedIterator<A>
    ) {
        store = Store(
            initialState: PostScrollState<A>(),
            reducer: PostScrollReducer(postViewFeedIteratorSupplier: postViewFeedIteratorSupplier).buildReducer(),
            environment: PostScrollEnvironment(
                mainQueue: .main,
                postFeedMessenger: postFeedMessenger
            )
        )
    }

    @ViewBuilder public func buildView() -> some View {
        WithViewStore(store) { viewStore in
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

public struct ImagePostScrollView: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<ImagePostView>

    public init(postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { (environment: PostScrollEnvironment) -> PostViewFeedIterator<ImagePostView> in
            environment
                .postFeedMessenger
                .getGlobalPostFeed()
                .makeIterator()
        }
    }

    public var body: some View {
        postScrollViewBuilder.buildView()
    }
}

public struct CommentScrollView: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<CommentView>

    public init(postId: UUID, postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { (environment: PostScrollEnvironment) -> PostViewFeedIterator<CommentView> in
            environment
                .postFeedMessenger
                .getCommentFeed(postId: postId)
                .makeIterator()
        }
    }

    public var body: some View {
        postScrollViewBuilder.buildView()
    }
}
