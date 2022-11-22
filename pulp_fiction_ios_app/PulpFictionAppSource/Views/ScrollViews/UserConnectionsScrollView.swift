//
//  UserConnectionsScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

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
struct UserConnectionsScrollView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var userConnectionsFilterDropDownMenu: SymbolWithDropDownMenu<UserConnectionsFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 25,
        symbolColor: .gray,
        menuOptions: UserConnectionsFilter.allCases,
        initialMenuSelection: .Following
    )

    var body: some View {
        ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<UserConnectionView> in
            buildPostViewFeed(userConnectionsFilterDropDownMenu.currentSelection)
                .makeIterator()
        }.toolbar {
            UserConnectionsTopNavigationBar(userConnectionsFilterDropDownMenu: userConnectionsFilterDropDownMenu)
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
