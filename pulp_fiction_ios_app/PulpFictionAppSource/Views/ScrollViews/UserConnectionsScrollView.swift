//
//  UserConnectionsScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Possible filters for UserConnectionsScrollView
enum UserConnectionsFilter: String, DropDownMenuOption {
    /// View shows users current user is following
    case Following
    /// View shows users following current user
    case Followers
}

/// Reducer for UserConnectionsScrollView
struct UserConnectionsScrollReducer: ReducerProtocol {
    struct State: Equatable {
        /// The currently selected UserConnectionsFilter
        var currentUserConnectionsFilter: UserConnectionsFilter = .Following
    }

    enum Action {
        /// Updates currentUserConnectionsFilter
        case updateCurrentUserConnectionsFilter(UserConnectionsFilter)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCurrentUserConnectionsFilter(newUserConnectionsFilter):
            state.currentUserConnectionsFilter = newUserConnectionsFilter
            return .none
        }
    }
}

/// View thay scrolls through a user's connections (e.g. their followers and followees)
struct UserConnectionsScrollView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<UserConnectionsScrollReducer> = Store(
        initialState: UserConnectionsScrollReducer.State(),
        reducer: UserConnectionsScrollReducer()
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<UserConnectionView> in
                buildPostViewFeed(viewStore.state.currentUserConnectionsFilter)
                    .makeIterator()
            }.toolbar{
                UserConnectionsTopNavigationBar(
                    userConnectionsFilter: viewStore.state.currentUserConnectionsFilter,
                    dropDownMenuSelectionAction: { newUserConnectionsFilter in
                        viewStore.send(.updateCurrentUserConnectionsFilter(newUserConnectionsFilter))
                    }
                )
            }
        }
    }

    private func buildPostViewFeed(_ userConnectionsFilter: UserConnectionsFilter) -> PostViewFeed<UserConnectionView> {
        switch userConnectionsFilter {
        case .Following:
            return postFeedMessenger
                .getFollowingScrollFeed(userId: loggedInUserPostData.userId)
        case .Followers:
            return postFeedMessenger
                .getFollowersScrollFeed(userId: loggedInUserPostData.userId)
        }
    }
}