//
//  UserConnectionView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/22/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for updating UserConnectionView
struct UserConnectionViewReducer: ReducerProtocol {
    struct State: Equatable {
        /// Boolean that shows whether or not the current user following the user connection
        var isFollowing: Bool = true
    }

    enum Action {
        /// Updates the following status of a user connection
        case updateIsFollowing(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateIsFollowing(newIsFollowing):
            state.isFollowing = newIsFollowing
            return .none
        }
    }
}

/// Constructs a view that shows a users connection with another user (e.g. a follower or a followee)
struct UserConnectionView: ScrollableContentView {
    let id: Int
    let userPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<SwipablePostViewReducer<UserConnectionViewReducer>> = Store(
        initialState: SwipablePostViewReducer.State(viewComponentsState: UserConnectionViewReducer.State()),
        reducer: SwipablePostViewReducer(
            viewComponentsReducerSuplier: { UserConnectionViewReducer() },
            updateViewComponentsActionSupplier: { _, dragOffset in
                if (dragOffset.width + 1e-6) < 0 {
                    return .updateIsFollowing(true)
                } else if (dragOffset.width - 1e-6) > 0 {
                    return .updateIsFollowing(false)
                } else {
                    return nil
                }
            }
        )
    )

    static func == (lhs: UserConnectionView, rhs: UserConnectionView) -> Bool {
        lhs.id == rhs.id
            && lhs.userPostData == rhs.userPostData
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            SwipableContentView(
                store: store,
                swipeLeftSymbolName: "figure.stand.line.dotted.figure.stand",
                swipeRightSymbolName: "figure.dress.line.vertical.figure"
            ) {
                HStack {
                    UserPostView(
                        userPostData: userPostData,
                        postFeedMessenger: postFeedMessenger
                    )
                    Spacer()
                    buildFollowingNotFolowingCaption(viewStore.state.viewComponentsState.isFollowing)
                }
            }
        }
    }

    @ViewBuilder func buildFollowingNotFolowingCaption(_ isFollowing: Bool) -> some View {
        let followingOpacity = isFollowing ? 1.0 : 0.0
        let notFollowingOpacity = !isFollowing ? 1.0 : 0.0
        let backgroundColor: Color = isFollowing ? .orange : .blue
        ZStack {
            Caption("Following")
                .padding()
                .foregroundColor(.white)
                .opacity(followingOpacity)
            Caption("Not Following")
                .padding()
                .foregroundColor(.white)
                .opacity(notFollowingOpacity)
        }.background(backgroundColor)
    }
}
