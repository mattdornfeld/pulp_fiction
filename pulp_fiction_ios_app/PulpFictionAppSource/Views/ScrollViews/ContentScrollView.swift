//
//  ContentScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Bow
import ComposableArchitecture
import Logging
import SwiftUI

/// Function that constructs a Either<PulpFictionRequestError, A>
typealias PostViewEitherSupplier<A: ScrollableContentView> = (Int, Post, ContentScrollViewStore<A>) -> Either<PulpFictionRequestError, A>

/// A protocol from which which all Views that can be embedded in a scroll should inherit
protocol ScrollableContentView: View, Identifiable, Equatable {
    /// The integer position of the piece of content in the feed
    var id: Int { get }
    /// The metadata for the post
    var postMetadata: PostMetadata { get }
    /// Function for constructing a PostViewEitherSupplier
    static func getPostViewEitherSupplier(
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) -> PostViewEitherSupplier<Self>
}

/// Reducer that manages scrolling through an infinite list of content
struct ContentScrollViewReducer<A: ScrollableContentView>: ReducerProtocol {
    let postViewEitherSupplier: (Int, Post, ContentScrollViewStore<A>) -> Either<PulpFictionRequestError, A>
    private let logger: Logger = .init(label: String(describing: ContentScrollViewReducer.self))
    private let restartScrollOffsetThreshold = 10.0

    struct State: Equatable {
        @EquatableIgnore
        var postStreamMaybe: PostStream? = nil
        /// Queue for storing ScrollableContentViews that will be rendered in the feed
        var postViews: Queue<A> = .init()
        /// Indicator that shows new content is being loaded into the feed
        private(set) var feedLoadProgressIndicatorOpacity: Double = 0.0
        /// Post indices for which loadMorePosts was called. We keep track of this to make sure we don't double load posts
        var lastVisiblePostIndices: Set<Int> = .init()
        /// These post ids will be filtered from the feed. Used to remove deleted posts from local feed without refreshing feed.
        var postIdsToFilterFromFeed: Set<UUID> = .init()

        mutating func hideFeedLoadProgressIndicator() {
            feedLoadProgressIndicatorOpacity = 0.0
        }

        func isFeedLoadProgressIndicatorShowing() -> Bool {
            abs(feedLoadProgressIndicatorOpacity - 1.0) < 1e-10
        }

        mutating func showFeedLoadProgressIndicator() {
            feedLoadProgressIndicatorOpacity = 1.0
        }

        func shouldFeedIncludePost(postMetadata: PostMetadata) -> Bool {
            !postIdsToFilterFromFeed.contains(postMetadata.postUpdateIdentifier.postId)
        }
    }

    enum Action {
        /// Enqueue posts into the scroll.
        case enqueuePostsToScroll([(Int, Post)], ContentScrollViewStore<A>)
        /// Called every time a post appears in the scroll. Checks to see if old posts should be removed from a scroll and loads new posts into the scroll if necessary.
        case refreshScrollIfNecessary(Int)
        /// Dequeus old posts from scroll if necessary
        case dequeuePostsFromScrollIfNecessary(Int)
        /// Updates the opacity of progress indicator. Set to 1.0 if posts are being loaded into the scroll and 0.0 otherwise.
        case updateFeedLoadProgressIndicatorOpacity(Bool)
        /// Called when there are no more posts left to scroll through
        case stopScroll
        /// Restarts the scroll on a drag up action if offset is greater than threshold
        case restartScrollIfOffsetGreaterThanThreshold(CGFloat)
        /// Restarts the scroll
        case restartScroll
        /// Filter post from local feed
        case filterPostFromFeed(PostMetadata)
        case startPostStream(PostStream)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .enqueuePostsToScroll(postIndicesAndPosts, viewStore):
            state.showFeedLoadProgressIndicator()
            let scrollableContentViews = postIndicesAndPosts.map { postIndex, post in
                postViewEitherSupplier(postIndex, post, viewStore)
                    .onSuccess { _ in
                        self.logger.debug(
                            "Successfully built PostView",
                            metadata: [
                                "queueSize": "\(state.postViews.elements.count)",
                                "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                                "currentPostIndex": "\(postIndex)",
                            ]
                        )
                    }
                    .onError { cause in
                        self.logger.error(
                            "Error building PostView",
                            metadata: [
                                "cause": "\(cause)",
                                "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                                "postIndex": "\(postIndex)",
                            ]
                        )
                    }
            }.flattenError()

            state.postViews.enqueue(scrollableContentViews)

            return .task { .updateFeedLoadProgressIndicatorOpacity(false) }

        case let .refreshScrollIfNecessary(currentPostIndex):
            state.showFeedLoadProgressIndicator()
            return .task { .dequeuePostsFromScrollIfNecessary(currentPostIndex) }

        case let .dequeuePostsFromScrollIfNecessary(currentPostIndex):
            if state.postViews.isClosed() {
                return .none
            }

            state.showFeedLoadProgressIndicator()

            let alreadyLoadedForPostIndex = state
                .lastVisiblePostIndices
                .contains(currentPostIndex)

            logger.debug(
                "Attempting to load posts for currentPostIndex",
                metadata: [
                    "currentPostIndex": "\(currentPostIndex)",
                    "lastVisiblePostIndices": "\(state.lastVisiblePostIndices)",
                ]
            )

            let isLastPostVisible = state
                .postViews
                .elements
                .last
                .map { $0.id == currentPostIndex }^
                .getOrElse(true)
            let isQueueFull = state.postViews.elements.count == PostFeedConfigs.postFeedMaxQueueSize
            let shouldClearPosts = isQueueFull
            let shouldLoadMorePosts = !alreadyLoadedForPostIndex && isLastPostVisible

            logger.debug(
                "Deciding whether to clear posts from feed and load more",
                metadata: [
                    "alreadyLoadedForPostIndex": "\(alreadyLoadedForPostIndex)",
                    "isLastPostVisible": "\(isLastPostVisible)",
                    "isQueueFull": "\(isQueueFull)",
                    "shouldClearPosts": "\(shouldClearPosts)",
                    "shouldLoadMorePosts": "\(shouldLoadMorePosts)",
                ]
            )

            if shouldClearPosts, shouldLoadMorePosts {
                logger.debug(
                    "Queue is full. Making room.",
                    metadata: [
                        "queueSize": "\(state.postViews.elements.count)",
                        "currentPostIndex": "\(currentPostIndex)",
                    ]
                )

                state.postViews.dequeue(numElements: PostFeedConfigs.numPostReturnedPerRequest)
                state.postStreamMaybe.map { $0.loadMorePosts(state: &state, currentPostIndex: currentPostIndex) }
            } else if shouldLoadMorePosts {
                state.postStreamMaybe.map { $0.loadMorePosts(state: &state, currentPostIndex: currentPostIndex) }
            }

            logger.debug(
                "dequeuePostsFromScrollIfNecessary is finished",
                metadata: [
                    "shouldClearPosts": "\(shouldClearPosts)",
                    "shouldLoadMorePosts": "\(shouldLoadMorePosts)",
                ]
            )

            return .task { .updateFeedLoadProgressIndicatorOpacity(false) }

        case let .updateFeedLoadProgressIndicatorOpacity(shouldShowFeedLoadProgressIndicator):
            if shouldShowFeedLoadProgressIndicator {
                state.showFeedLoadProgressIndicator()
            } else {
                state.hideFeedLoadProgressIndicator()
            }
            return .none

        case .stopScroll:
            state.postViews.close()
            state.postStreamMaybe.map { $0.closeStream() }
            return .none

        case let .restartScrollIfOffsetGreaterThanThreshold(newOffset):
            if newOffset >= restartScrollOffsetThreshold, !state.isFeedLoadProgressIndicatorShowing() {
                return .task { .restartScroll }
            } else if newOffset <= 1.0, state.isFeedLoadProgressIndicatorShowing() {
                return .task { .updateFeedLoadProgressIndicatorOpacity(false) }
            }

            return .none

        case .restartScroll:
            state.showFeedLoadProgressIndicator()
            state.postStreamMaybe.map { $0.restartStream() }
            state.postViews = .init()
            state.lastVisiblePostIndices = .init()
            return .task { .updateFeedLoadProgressIndicatorOpacity(false) }

        case let .filterPostFromFeed(postMetadata):
            let postId = postMetadata.postUpdateIdentifier.postId
            if !state.postIdsToFilterFromFeed.contains(postId) {
                state.postIdsToFilterFromFeed.insert(postId)
            }
            return .none

        case let .startPostStream(postStream):
            state.postStreamMaybe = postStream
            return .none
        }
    }
}

private extension Queue {
    convenience init() {
        self.init(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
    }
}

private extension PostStream {
    /// Send request to backend server to load more posts into stream.
    /// - Parameters:
    ///   - state: The current state of the ViewStore
    ///   - currentPostIndex: The post index that last appeared
    func loadMorePosts<A: ScrollableContentView>(state: inout ContentScrollViewReducer<A>.State, currentPostIndex: Int) {
        logger.debug(
            "Loading more posts",
            metadata: [
                "queueSize": "\(state.postViews.elements.count)",
                "currentPostIndex": "\(currentPostIndex)",
            ]
        )

        loadMorePosts()
        state.lastVisiblePostIndices.insert(currentPostIndex)
    }
}

typealias PrepenedToScrollView = View
typealias ContentScrollViewStore<A: ScrollableContentView> = PulpFictionViewStore<ContentScrollViewReducer<A>>

/// Build a view that shows a feed of scrollable content
struct ContentScrollView<A: ScrollableContentView, B: PrepenedToScrollView>: View {
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    private let prependToBeginningOfScroll: B
    @ObservedObject var viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>
    @GestureState private var dragOffset: CGFloat = -100

    /// Builds a ContentScrollView
    /// - Parameters:
    ///   - prependToBeginningOfScroll: View to prepend to beginning of scroll
    ///   - postFeedMessenger:
    ///   - backendMessenger:
    ///   - notificationBannerViewStore:
    ///   - postViewEitherSupplier: Function constructs a ScrollableContentView from a Post and its index in the feed
    ///   - postStreamSupplier: Function that constructs a PostStream
    init(
        prependToBeginningOfScroll: B = EmptyView(),
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        postStreamSupplier: @escaping (ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>) -> PostStream

    ) {
        self.prependToBeginningOfScroll = prependToBeginningOfScroll
        viewStore = ContentScrollView.buildViewStore(postViewEitherSupplier: A.getPostViewEitherSupplier(
            postFeedMessenger: postFeedMessenger,
            backendMessenger: backendMessenger,
            notificationBannerViewStore: notificationBannerViewStore
        ))
        viewStore.send(.startPostStream(postStreamSupplier(viewStore)))
    }

    static func buildViewStore<A: ScrollableContentView>(
        postViewEitherSupplier: @escaping (Int, Post, ContentScrollViewStore<A>) -> Either<PulpFictionRequestError, A>
    ) -> ContentScrollViewStore<A> {
        let store = Store(
            initialState: ContentScrollViewReducer<A>.State(),
            reducer: ContentScrollViewReducer<A>(postViewEitherSupplier: postViewEitherSupplier)
        )
        return ViewStore(store)
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center) {
                    prependToBeginningOfScroll

                    LazyVStack(alignment: .leading) {
                        ForEach(viewStore.postViews.elements.filter { scrollableContentView in
                            viewStore
                                .state
                                .shouldFeedIncludePost(postMetadata: scrollableContentView.postMetadata)
                        }) { currentPost in
                            currentPost.onAppear {
                                viewStore.send(.refreshScrollIfNecessary(currentPost.id))
                            }
                        }
                    }

                    Spacer()

                    Caption(
                        text: "You have reached the end\nTry refreshing the feed to see new posts",
                        alignment: .center,
                        color: .gray
                    )
                    .padding()
                    .opacity(viewStore.state.isFeedLoadProgressIndicatorShowing() ? 0.0 : 1.0)
                }
                .frame(minHeight: geometryProxy.size.height)
                .anchorPreference(key: OffsetPreferenceKey.self, value: .top) {
                    geometryProxy[$0].y
                }
                .onPreferenceChange(OffsetPreferenceKey.self) { newOffset in
                    viewStore.send(.restartScrollIfOffsetGreaterThanThreshold(newOffset))
                }
            }.overlay {
                ProgressView()
                    .scaleEffect(progressIndicatorScaleFactor, anchor: .center)
                    .opacity(viewStore.state.feedLoadProgressIndicatorOpacity)
            }
        }.onDisappear {
            viewStore.send(.stopScroll)
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static let threshold: CGFloat = 10.0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
