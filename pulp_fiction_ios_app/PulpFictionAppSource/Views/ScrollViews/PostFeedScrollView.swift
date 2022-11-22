//
//  PostFeedScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

enum PostFeedFilter: String, DropDownMenuOption {
    case Global
    case Following
}

struct PostFeedTopNavigationBar: ToolbarContent {
    let postFeedFilter: PostFeedFilter
    let postFeedMessenger: PostFeedMessenger
    let loggedInUserPostData: UserPostData
    let postFeedFilterDropDownMenuView: SymbolWithDropDownMenuView<PostFeedFilter>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Title("Pulp Fiction")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 0.001) {
                Symbol(
                    symbolName: "plus",
                    size: 20,
                    color: .gray
                ).navigateOnTap(
                    destination: PostCreatorView(
                        loggedInUserPostData: loggedInUserPostData,
                        postFeedMessenger: postFeedMessenger
                    )
                )

                postFeedFilterDropDownMenuView
            }
        }
    }
}

/// View that scrolls through a feed of posts
struct PostFeedScrollView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var postFeedFilterDropDownMenu: SymbolWithDropDownMenu<PostFeedFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: PostFeedFilter.allCases,
        initialMenuSelection: .Global
    )

    var body: some View {
        ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
            getPostFeed(postFeedFilterDropDownMenu.currentSelection)
                .makeIterator()
        }
        .toolbar {
            PostFeedTopNavigationBar(
                postFeedFilter: postFeedFilterDropDownMenu.currentSelection,
                postFeedMessenger: postFeedMessenger,
                loggedInUserPostData: loggedInUserPostData,
                postFeedFilterDropDownMenuView: postFeedFilterDropDownMenu.view
            )
        }
    }

    func getPostFeed(_ postFeedFilter: PostFeedFilter) -> PostViewFeed<ImagePostView> {
        switch postFeedFilter {
        case .Global:
            return postFeedMessenger
                .getGlobalPostFeed()
        case .Following:
            return postFeedMessenger
                .getFollowingPostFeed(userId: loggedInUserPostData.userId)
        }
    }
}
