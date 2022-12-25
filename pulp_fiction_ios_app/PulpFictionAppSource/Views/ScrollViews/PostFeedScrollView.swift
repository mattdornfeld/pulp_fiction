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

struct PostFeedTopNavigationBar: PulpFictionToolbarContent {
    let postFeedFilter: PostFeedFilter
    let externalMessengers: ExternalMessengers
    let loggedInUserPostData: UserPostData
    let postFeedFilterDropDownMenuView: SymbolWithDropDownMenuView<PostFeedFilter>
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
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
                        externalMessengers: externalMessengers,
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
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var postFeedFilterDropDownMenu: SymbolWithDropDownMenu<PostFeedFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: PostFeedFilter.allCases,
        initialMenuSelection: .Global
    )
    var contentScrollView: ContentScrollView<ImagePostView, EmptyView> {
        ContentScrollView(
            externalMessengers: externalMessengers,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            getPostFeed(
                postFeedFilter: postFeedFilterDropDownMenu.currentSelection,
                viewStore: viewStore
            )
        }
    }

    var body: some View {
        contentScrollView
            .toolbar {
                PostFeedTopNavigationBar(
                    postFeedFilter: postFeedFilterDropDownMenu.currentSelection,
                    externalMessengers: externalMessengers,
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
