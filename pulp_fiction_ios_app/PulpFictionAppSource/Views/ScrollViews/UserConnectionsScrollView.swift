//
//  UserConnectionsScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Bow
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

/// Top navigation bar view for the user connections page
struct UserConnectionsTopNavigationBar: ToolbarContent {
    @ObservedObject var userConnectionsFilterDropDownMenu: SymbolWithDropDownMenu<UserConnectionsFilter>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(userConnectionsFilterDropDownMenu.currentSelection.rawValue)
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            userConnectionsFilterDropDownMenu.view.padding(.trailing, 7.5)
        }
    }
}

/// View thay scrolls through a user's connections (e.g. their followers and followees)
struct UserConnectionsScrollView: ScrollViewParent {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let postViewEitherSupplier: (Int, Post) -> Either<PulpFictionRequestError, UserConnectionView>
    @ObservedObject private var userConnectionsFilterDropDownMenu: SymbolWithDropDownMenu<UserConnectionsFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 25,
        symbolColor: .gray,
        menuOptions: UserConnectionsFilter.allCases,
        initialMenuSelection: .Following
    )

    init(loggedInUserPostData: UserPostData, postFeedMessenger: PostFeedMessenger, backendMessenger: BackendMessenger) {
        self.loggedInUserPostData = loggedInUserPostData
        self.postFeedMessenger = postFeedMessenger
        self.backendMessenger = backendMessenger
        postViewEitherSupplier = { postViewIndex, postProto in
            let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()

            return binding(
                userPostDataEither <- postFeedMessenger.postDataMessenger
                    .getPostData(postProto)
                    .unsafeRunSyncEither(on: .global(qos: .userInteractive))
                    .flatMap { postDataOneOf in postDataOneOf.toUserPostData() }^,
                yield: UserConnectionView(
                    id: postViewIndex,
                    userPostData: userPostDataEither.get,
                    postFeedMessenger: postFeedMessenger,
                    backendMessenger: backendMessenger,
                    loggedInUserPostData: postFeedMessenger.loginSession.loggedInUserPostData
                )
            )^
        }
    }

    var body: some View {
        ContentScrollView(postViewEitherSupplier: postViewEitherSupplier) { viewStore in
            buildPostViewFeed(
                userConnectionsFilter: userConnectionsFilterDropDownMenu.currentSelection,
                viewStore: viewStore
            )
        }.toolbar {
            UserConnectionsTopNavigationBar(userConnectionsFilterDropDownMenu: userConnectionsFilterDropDownMenu)
        }
    }

    private func buildPostViewFeed(
        userConnectionsFilter: UserConnectionsFilter,
        viewStore: ViewStore<ContentScrollViewReducer<UserConnectionView>.State, ContentScrollViewReducer<UserConnectionView>.Action>
    ) -> PostStream {
        switch userConnectionsFilter {
        case .Following:
            return postFeedMessenger
                .getFollowingScrollFeed(userId: loggedInUserPostData.userId, viewStore: viewStore)
        case .Followers:
            return postFeedMessenger
                .getFollowersScrollFeed(userId: loggedInUserPostData.userId, viewStore: viewStore)
        }
    }
}
