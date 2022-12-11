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
        var postViews: Queue<A> = .init(maxSize: PostFeedConfigs.postFeedMaxQueueSize)
        /// Indicator that shows new content is being loaded into the feed
        var feedLoadProgressIndicatorOpacity: Double = 0.0
    }

    enum Action {
        /// This action is called on view load. It starts the postStreamIterator and begins loading posts into the view.
        case startScroll
        /// Refreshes the feed scroll with new content
        case refreshScroll
        case enqueuePost(Int, Post)
        case updateFeedLoadProgressIndicatorOpacity(CGFloat)
    }

    enum PostScrollErrors {
        class postStreamIteratorNotStarted: PulpFictionRequestError {}
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .startScroll:
            state.feedLoadProgressIndicatorOpacity = 0.0
            return .none

        case .refreshScroll:
            state.feedLoadProgressIndicatorOpacity = 1.0
//            state.refreshpostStream()
            state.feedLoadProgressIndicatorOpacity = 0.0
            return .task {
                .startScroll
            }

        case let .enqueuePost(currentPostIndex, post):
            state.feedLoadProgressIndicatorOpacity = 1.0
            postViewEitherSupplier(currentPostIndex, post).mapRight { scrollableContentView in
                state.postViews.enqueue(scrollableContentView)
            }
            .onSuccess {
                self.logger.debug(
                    "Enqueued post from feed",
                    metadata: [
                        "queueSize": "\(state.postViews.elements.count)",
                        "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                        "currentPostIndex": "\(currentPostIndex)",
                    ]
                )
            }
            .onError { cause in
                self.logger.error(
                    "Error building PostView",
                    metadata: [
                        "cause": "\(cause)",
                        "postId": "\(post.metadata.postUpdateIdentifier.postID)",
                        "postIndex": "\(currentPostIndex)",
                    ]
                )
            }
            return .task { .updateFeedLoadProgressIndicatorOpacity(0.0) }

        case let .updateFeedLoadProgressIndicatorOpacity(newFeedLoadProgressIndicatorOpacity):
            state.feedLoadProgressIndicatorOpacity = newFeedLoadProgressIndicatorOpacity
            return .none
        }
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
            let viewStore = ViewStore(store)
            viewStore.send(.startScroll)
            return viewStore
        }()
        self.viewStore = viewStore
        postStream = postStreamSupplier(viewStore)
    }

    func startScroll(_ viewStore: ViewStore<ContentScrollViewReducer<A>.State, ContentScrollViewReducer<A>.Action>) -> some View {
        viewStore.send(.startScroll)
        return EmptyView()
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
                            currentPost
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
