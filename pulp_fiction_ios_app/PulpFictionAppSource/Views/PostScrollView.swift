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
    case startScroll
    case loadMorePostsIfNeeded(ImagePostView)
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
            state.postViewFeedIteratorMaybe = {
                let postViewFeedIterator = environment
                    .postFeedMessenger
                    .getGlobalPostFeed()
                    .makeIterator()

                logger.debug("Started post feed iterator")

                state.loadMorePostsIfNeeded(postViewFeedIterator, 0)

                return postViewFeedIterator
            }()
            return .none

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
                LazyVStack(alignment: .leading) {
                    ForEach(viewStore.state.postViews) { currentPost in
                        currentPost.onAppear {
                            viewStore.send(.loadMorePostsIfNeeded(currentPost))
                        }
                    }
                }
            }
            .onAppear { viewStore.send(.startScroll) }
        }
    }
}
