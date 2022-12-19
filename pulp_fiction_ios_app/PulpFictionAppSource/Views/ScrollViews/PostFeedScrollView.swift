//
//  PostFeedScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Describes the possible options for the main post feed
enum PostFeedFilter: String, DropDownMenuOption {
    /// Feed will contain all posts
    case Global
    /// Feed will contain only the posts from users the logged in user is following
    case Following
}

struct PostFeedTopNavigationBar: ToolbarContent {
    let postFeedFilter: PostFeedFilter
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let loggedInUserPostData: UserPostData
    let postFeedFilterDropDownMenuView: SymbolWithDropDownMenuView<PostFeedFilter>
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

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
                        postFeedMessenger: postFeedMessenger,
                        backendMessenger: backendMessenger,
                        notificationBannerViewStore: notificationBannerViewStore
                    )
                )

                postFeedFilterDropDownMenuView
            }
        }
    }
}

/// View that scrolls through a feed of posts
struct PostFeedScrollView: ScrollViewParent {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var postFeedFilterDropDownMenu: SymbolWithDropDownMenu<PostFeedFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: PostFeedFilter.allCases,
        initialMenuSelection: .Global
    )

    var body: some View {
        ContentScrollView(
            postFeedMessenger: postFeedMessenger,
            backendMessenger: backendMessenger,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            getPostFeed(
                postFeedFilter: postFeedFilterDropDownMenu.currentSelection,
                viewStore: viewStore
            )
        }
        .toolbar {
            PostFeedTopNavigationBar(
                postFeedFilter: postFeedFilterDropDownMenu.currentSelection,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                loggedInUserPostData: loggedInUserPostData,
                postFeedFilterDropDownMenuView: postFeedFilterDropDownMenu.view,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
    }

    private func getPostFeed(
        postFeedFilter: PostFeedFilter,
        viewStore: ViewStore<ContentScrollViewReducer<ImagePostView>.State, ContentScrollViewReducer<ImagePostView>.Action>
    ) -> PostStream {
        switch postFeedFilter {
        case .Global:
            return postFeedMessenger
                .getGlobalPostFeed(viewStore: viewStore)
        case .Following:
            return postFeedMessenger
                .getFollowingPostFeed(userId: loggedInUserPostData.userId, viewStore: viewStore)
        }
    }
}
