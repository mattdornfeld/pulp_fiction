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

/// Reducer that manages scrolling through an infinite list of content
struct ContentScrollViewReducer<A: ScrollableContentView>: ReducerProtocol {
    let postViewFeedIteratorSupplier: () -> PostViewFeedIterator<A>

    struct State: Equatable {
        /// The iterator used to retrieve posts from the backend API and data store
        var postViewFeedIteratorMaybe: PostViewFeedIterator<A>? = nil
        /// The PostView objects currently available in the scroll
        var postViews: [A] = []
        /// Indicator that shows new content is being loaded into the feed
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

                logger.debug(
                    "Posts added to scroll",
                    metadata: [
                        "currentPostViewIndex": "\(currentPostViewIndex)",
                        "numPostsInScroll": "\(postViews.count)",
                    ]
                )

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

    enum Action {
        /// This action is called on view load. It starts the PostViewFeedIterator and begins loading posts into the view.
        case startScroll
        /// Refreshes the feed scroll with new content
        case refreshScroll
        /// Loads more posts if necessary. Triggered on scroll.
        case loadMorePostsIfNeeded(any ScrollableContentView)
    }

    enum PostScrollErrors {
        class PostViewFeedIteratorNotStarted: PulpFictionRequestError {}
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .startScroll:
            if state.postViewFeedIteratorMaybe != nil {
                return .none
            }

            state.postViews = []
            state.postViewFeedIteratorMaybe = {
                let postViewFeedIterator = postViewFeedIteratorSupplier()

                logger.debug("Started post feed iterator")

                state.loadMorePostsIfNeeded(postViewFeedIterator, 0)

                return postViewFeedIterator
            }()
            state.feedLoadProgressIndicatorOpacity = 0.0
            return .none

        case .refreshScroll:
            state.feedLoadProgressIndicatorOpacity = 1.0
            state.postViewFeedIteratorMaybe = nil
            return .task {
                .startScroll
            }

        case let .loadMorePostsIfNeeded(currentPostView):
            state.postViewFeedIteratorMaybe.map { postViewFeedIterator in
                state.loadMorePostsIfNeeded(postViewFeedIterator, currentPostView.id)
            }
            .toEither(PostScrollErrors.PostViewFeedIteratorNotStarted())
            .mapLeft { cause in
                logger.error(
                    "Error loading posts",
                    metadata: [
                        "cause": "\(cause)",
                    ]
                )
            }

            return .none
        }
    }
}

extension ContentScrollView where B == EmptyView {
    init(
        postFeedMessenger: PostFeedMessenger,
        postViewFeedIteratorSupplier: @escaping () -> PostViewFeedIterator<A>
    ) {
        self.init(
            postFeedMessenger: postFeedMessenger,
            prependToBeginningOfScroll: EmptyView(),
            postViewFeedIteratorSupplier: postViewFeedIteratorSupplier
        )
    }
}

/// Build a view that shows a feed of scrollable content
struct ContentScrollView<A: ScrollableContentView, B: View>: View {
    private let store: ComposableArchitecture.StoreOf<ContentScrollViewReducer<A>>
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    private let prependToBeginningOfScroll: B
    @GestureState private var dragOffset: CGFloat = -100

    /// Builds a ContentScrollView
    /// - Parameters:
    ///   - postFeedMessenger: Messenger that calls backend API and post data store to construct post feeds
    ///   - prependToBeginningOfScroll: View to prepend to beginning of scroll
    ///   - postViewFeedIteratorSupplier: Function that constructs the views which make up the items of the scroll
    init(
        postFeedMessenger _: PostFeedMessenger,
        prependToBeginningOfScroll: B,
        postViewFeedIteratorSupplier: @escaping () -> PostViewFeedIterator<A>
    ) {
        store = Store(
            initialState: ContentScrollViewReducer<A>.State(),
            reducer: ContentScrollViewReducer<A>(postViewFeedIteratorSupplier: postViewFeedIteratorSupplier)
        )
        self.prependToBeginningOfScroll = prependToBeginningOfScroll
    }

    func startScroll(_ viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>) -> some View {
        viewStore.send(.startScroll)
        return EmptyView()
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            GeometryReader { geometryProxy in
                ScrollView {
                    VStack(alignment: .center) {
                        ProgressView()
                            .scaleEffect(progressIndicatorScaleFactor, anchor: .center)
                            .opacity(viewStore.state.feedLoadProgressIndicatorOpacity)

                        startScroll(viewStore)
                        prependToBeginningOfScroll

                        LazyVStack(alignment: .leading) {
                            ForEach(viewStore.state.postViews) { currentPost in
                                currentPost.onAppear {
                                    viewStore.send(.loadMorePostsIfNeeded(currentPost))
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
                .onDragUp { viewStore.send(.refreshScroll) }
            }
        }
    }
}
