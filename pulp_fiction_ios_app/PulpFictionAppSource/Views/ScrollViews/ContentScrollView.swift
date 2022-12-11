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

private let logger: Logger = .init(label: String(describing: "ScrollableContentView"))

/// A protocol from which which all Views that can be embedded in a scroll should inherit
public protocol ScrollableContentView: View, Identifiable, Equatable {
    var id: Int { get }
}

@propertyWrapper
struct EquatableIgnore<Value>: Equatable {
    var wrappedValue: Value

    static func == (_: EquatableIgnore<Value>, _: EquatableIgnore<Value>) -> Bool {
        true
    }
}

/// Reducer that manages scrolling through an infinite list of content
struct ContentScrollViewReducer<A: ScrollableContentView>: ReducerProtocol {
    let postViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, A>
    private let logger: Logger = .init(label: String(describing: ContentScrollViewReducer.self))

    struct State: Equatable {
        /// Queue for storing ScrollableContentViews that will be rendered in the feed
        var postViews: Queue<A> = .init(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
        /// Indicator that shows new content is being loaded into the feed
        var feedLoadProgressIndicatorOpacity: Double = 0.0
        /// Post indices for which loadMorePosts was called. We keep track of this to make sure we don't double load posts
        var lastVisiblePostIndices: Set<Int> = .init()
    }

    enum Action {
        /// Enqueue posts into the scroll.
        case enqueuePostsToScroll([(Int, Post)])
        /// Called every time a post appears in the scroll. Checks to see if old posts should be removed from a scroll and loads new posts into the scroll if necessary.
        case refreshScrollIfNecessary(Int, PostStream<A>)
        /// Dequeus old posts from scroll if necessary
        case dequeuePostsFromScrollIfNecessary(Int, PostStream<A>)
        /// Updates the opacity of progress indicator. Set to 1.0 if posts are being loaded into the scroll and 0.0 otherwise.
        case updateFeedLoadProgressIndicatorOpacity(CGFloat)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .enqueuePostsToScroll(postIndicesAndPosts):
            state.feedLoadProgressIndicatorOpacity = 1.0
            let scrollableContentViews = postIndicesAndPosts.map { postIndex, post in
                postViewEitherSupplier(postIndex, post)
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

            return .task { .updateFeedLoadProgressIndicatorOpacity(0.0) }

        case let .refreshScrollIfNecessary(currentPostIndex, postStream):
            state.feedLoadProgressIndicatorOpacity = 1.0
            return .task { .dequeuePostsFromScrollIfNecessary(currentPostIndex, postStream) }

        case let .dequeuePostsFromScrollIfNecessary(currentPostIndex, postStream):
            let alreadyLoadedForPostIndex = state
                .lastVisiblePostIndices
                .contains(currentPostIndex)

            let isLastPostVisible = state
                .postViews
                .elements
                .last
                .map { $0.id == currentPostIndex }^
                .getOrElse(true)

            let shouldClearPosts = state.postViews.elements.count == PostFeedConfigs.postFeedMaxQueueSize

            let shouldLoadMorePosts = !alreadyLoadedForPostIndex && isLastPostVisible

            if shouldClearPosts, shouldLoadMorePosts {
                logger.debug(
                    "Queue is full. Making room.",
                    metadata: [
                        "queueSize": "\(state.postViews.elements.count)",
                        "currentPostIndex": "\(currentPostIndex)",
                    ]
                )

                let dequeuedPosts = state.postViews.dequeue(numElements: PostFeedConfigs.numPostReturnedPerRequest)
                postStream.loadMorePosts(state: &state, currentPostIndex: currentPostIndex)
            } else if shouldLoadMorePosts {
                postStream.loadMorePosts(state: &state, currentPostIndex: currentPostIndex)
            }

            return .task { .updateFeedLoadProgressIndicatorOpacity(0.0) }

        case let .updateFeedLoadProgressIndicatorOpacity(newFeedLoadProgressIndicatorOpacity):
            state.feedLoadProgressIndicatorOpacity = newFeedLoadProgressIndicatorOpacity
            return .none
        }
    }
}

private extension PostStream {
    /// Send request to backend server to load more posts into stream.
    /// - Parameters:
    ///   - state: The current state of the ViewStore
    ///   - currentPostIndex: The post index that last appeared
    func loadMorePosts(state: inout ContentScrollViewReducer<A>.State, currentPostIndex: Int) {
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

/// Build a view that shows a feed of scrollable content
struct ContentScrollView<A: ScrollableContentView, B: View>: View {
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    private let prependToBeginningOfScroll: B
    private let postStream: PostStream<A>
    @GestureState private var dragOffset: CGFloat = -100
    @ObservedObject private var viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>

    /// Builds a ContentScrollView
    /// - Parameters:
    ///   - prependToBeginningOfScroll: View to prepend to beginning of scroll
    ///   - postViewEitherSupplier: Function constructs a ScrollableContentView from a Post and its index in the feed
    ///   - postStreamSupplier: Function that constructs a PostStream
    init(
        prependToBeginningOfScroll: B = EmptyView(),
        postViewEitherSupplier: @escaping (Int, Post) -> Either<PulpFictionRequestError, A>,
        postStreamSupplier: @escaping (ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>) -> PostStream<A>

    ) {
        self.prependToBeginningOfScroll = prependToBeginningOfScroll
        let viewStore = {
            let store = Store(
                initialState: ContentScrollViewReducer<A>.State(),
                reducer: ContentScrollViewReducer<A>(postViewEitherSupplier: postViewEitherSupplier)
            )
            return ViewStore(store)
        }()
        self.viewStore = viewStore
        postStream = postStreamSupplier(viewStore)
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView {
                VStack(alignment: .center) {
                    ProgressView()
                        .scaleEffect(progressIndicatorScaleFactor, anchor: .center)
                        .opacity(viewStore.state.feedLoadProgressIndicatorOpacity)

                    prependToBeginningOfScroll

                    LazyVStack(alignment: .leading) {
                        ForEach(viewStore.postViews.elements) { currentPost in
                            currentPost.onAppear {
                                viewStore.send(.refreshScrollIfNecessary(currentPost.id, self.postStream))
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
                }
                .frame(minHeight: geometryProxy.size.height)
            }
//            .onDragUp { viewStore.send(.refreshScroll) }
        }
    }
}
