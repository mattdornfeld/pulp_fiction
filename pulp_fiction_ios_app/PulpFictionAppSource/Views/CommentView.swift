//
//  CommentView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/9/22.
//

import Bow
import ComposableArchitecture
import Foundation
import Logging
import SwiftUI

private struct CommentViewReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadUserProfileView: Bool = false
    }

    enum Action {
        case updateShouldLoadUserProfileView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadUserProfileView(shouldLoadUserProfileView):
            state.shouldLoadUserProfileView = shouldLoadUserProfileView
            return .none
        }
    }
}

struct CommentView: SwipablePostView {
    private static let logger = Logger(label: String(describing: CommentView.self))
    let commentPostData: CommentPostData
    let creatorUserPostData: UserPostData
    let id: Int
    internal let swipablePostStore: ComposableArchitecture.StoreOf<PostSwipeViewReducer>
    private let store: ComposableArchitecture.StoreOf<CommentViewReducer>
    private let postFeedMessenger: PostFeedMessenger

    init(
        commentPostData: CommentPostData,
        creatorUserPostData: UserPostData,
        id: Int,
        postFeedMessenger: PostFeedMessenger
    ) {
        self.commentPostData = commentPostData
        self.creatorUserPostData = creatorUserPostData
        self.id = id
        swipablePostStore = CommentView.buildStore(
            postInteractionAggregates: commentPostData.postInteractionAggregates,
            loggedInUserPostInteractions: commentPostData.loggedInUserPostInteractions
        )
        store = Store(
            initialState: CommentViewReducer.State(),
            reducer: CommentViewReducer()
        )
        self.postFeedMessenger = postFeedMessenger
    }

    static func == (lhs: CommentView, rhs: CommentView) -> Bool {
        lhs.commentPostData == rhs.commentPostData
            && lhs.creatorUserPostData == rhs.creatorUserPostData
            && lhs.id == rhs.id
    }

    @ViewBuilder func postViewBuilder() -> some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading) {
                HStack(alignment: .bottom, spacing: 5) {
                    BoldCaption(creatorUserPostData.userDisplayName)
                        .navigateOnTap(
                            isActive: viewStore.binding(
                                get: \.shouldLoadUserProfileView,
                                send: CommentViewReducer.Action.updateShouldLoadUserProfileView(false)
                            ),
                            destination: UserProfileView(
                                userPostData: creatorUserPostData,
                                postFeedMessenger: postFeedMessenger
                            )
                        ) { viewStore.send(.updateShouldLoadUserProfileView(true)) }
                    buildPostLikeArrowView()
                    Spacer()
                    Caption(commentPostData.postMetadata.createdAt.formatAsStringForView()).foregroundColor(.gray)
                    Symbol(symbolName: "ellipsis")
                        .padding(.trailing, 10)
                        .padding(.bottom, 4)
                }
                Caption(commentPostData.body)
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
        }
    }

    static func create(
        postViewIndex: Int,
        commentPostData: CommentPostData,
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger
    ) -> Either<PulpFictionRequestError, CommentView> {
        let userAvatarUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            userAvatarUIImageEither <- userPostData.userPostContentData.toUIImage(),
            yield: CommentView(
                commentPostData: commentPostData,
                creatorUserPostData: userPostData,
                id: postViewIndex,
                postFeedMessenger: postFeedMessenger
            )
        )^.onError { cause in
            logger.error(
                "Error loading comment \(commentPostData.postMetadata.postUpdateIdentifier)",
                metadata: [
                    "cause": "\(cause)",
                ]
            )
        }
    }
}
