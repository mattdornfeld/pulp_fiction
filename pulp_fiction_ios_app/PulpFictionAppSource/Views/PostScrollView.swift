//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import ComposableArchitecture
import Logging
import SwiftUI

private let logger: Logger = .init(label: String(describing: "PostScrollView"))

/// A protocol from which which all Views that can be embedded in a scroll should inherit
public protocol ScrollableContentView: View, Identifiable, Equatable {
    var id: Int { get }
}

struct PostScrollViewReducer<A: ScrollableContentView>: ReducerProtocol {
    let postViewFeedIteratorSupplier: () -> PostViewFeedIterator<A>

    struct State: Equatable {
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

private struct PostScrollViewBuilder<A: ScrollableContentView> {
    private let store: ComposableArchitecture.StoreOf<PostScrollViewReducer<A>>
    private let progressIndicatorScaleFactor: CGFloat = 2.0
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    @GestureState private var dragOffset: CGFloat = -100

    init(
        postFeedMessenger _: PostFeedMessenger,
        postViewFeedIteratorSupplier: @escaping () -> PostViewFeedIterator<A>
    ) {
        store = Store(
            initialState: PostScrollViewReducer<A>.State(),
            reducer: PostScrollViewReducer<A>(postViewFeedIteratorSupplier: postViewFeedIteratorSupplier)
        )
    }

    @ViewBuilder internal func buildView() -> some View {
        buildView(.some(EmptyView()))
    }

    @ViewBuilder internal func buildView<Content: View>(_ prependToBeginningOfScrollMaybe: Option<Content> = .none()) -> some View {
        WithViewStore(store) { viewStore in
            GeometryReader { geometryProxy in
                ScrollView {
                    VStack(alignment: .center) {
                        ProgressView()
                            .scaleEffect(progressIndicatorScaleFactor, anchor: .center)
                            .opacity(viewStore.state.feedLoadProgressIndicatorOpacity)

                        prependToBeginningOfScrollMaybe
                            .toEither()
                            .mapLeft { _ in EmptyView() }
                            .toEitherView()

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
                            alignment: .center
                        )
                        .foregroundColor(.gray)
                        .padding()
                    }
                    .frame(minHeight: geometryProxy.size.height)
                }
                .onAppear { viewStore.send(.startScroll) }
                .onDragUp { viewStore.send(.refreshScroll) }
            }
        }
    }
}

struct PostFeedScrollView: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<ImagePostView>

    init(postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getGlobalPostFeed()
                .makeIterator()
        }
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { PostFeedTopNavigationBar() }) {
            postScrollViewBuilder.buildView()
        }
    }
}

struct UserProfileScrollView<Content: View>: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<ImagePostView>
    @ViewBuilder private let userProfileViewBuilder: () -> Content
    private let userPostData: UserPostData

    init(
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        userProfileViewBuilder: @escaping () -> Content
    ) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getUserProfilePostFeed(userId: userPostData.userId)
                .makeIterator()
        }
        self.userProfileViewBuilder = userProfileViewBuilder
        self.userPostData = userPostData
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { UserProfileTopNavigationBar(userPostData: userPostData) }) {
            postScrollViewBuilder.buildView(.some(userProfileViewBuilder()))
        }
    }
}

struct CommentsPageScrollView: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<CommentView>
    private let imagePostView: ImagePostView

    init(imagePostView: ImagePostView, postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<CommentView> in
            postFeedMessenger
                .getCommentFeed(postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId)
                .makeIterator()
        }
        self.imagePostView = imagePostView
    }

    var body: some View {
        postScrollViewBuilder.buildView(.some(
            VStack {
                imagePostView
                Divider()
                Caption("\(imagePostView.imagePostData.postInteractionAggregates.numChildComments.formatAsStringForView()) Comments")
                    .foregroundColor(.gray)
            })
        )
    }
}

struct UserConnectionsScrollView: View {
    private let postScrollViewBuilder: PostScrollViewBuilder<UserConnectionView>

    init(
        userId: UUID,
        postFeedMessenger: PostFeedMessenger
    ) {
        postScrollViewBuilder = PostScrollViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<UserConnectionView> in
            postFeedMessenger
                .getFollowedScrollFeed(userId: userId)
                .makeIterator()
        }
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { UserConnectionsTopNavigationBar() }) {
            postScrollViewBuilder.buildView()
        }
    }
}
