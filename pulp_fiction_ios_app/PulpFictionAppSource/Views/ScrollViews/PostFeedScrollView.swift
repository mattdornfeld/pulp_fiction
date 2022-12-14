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

enum PostFeedFilter: String, DropDownMenuOption {
    case Global
    case Following
}

struct PostFeedTopNavigationBar: ToolbarContent {
    let postFeedFilter: PostFeedFilter
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
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
                        postFeedMessenger: postFeedMessenger,
                        backendMessenger: backendMessenger
                    )
                )

                postFeedFilterDropDownMenuView
            }
        }
    }
}

/// View that scrolls through a feed of posts
struct PostFeedScrollView: ImagePostScrollView {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    @ObservedObject private var postFeedFilterDropDownMenu: SymbolWithDropDownMenu<PostFeedFilter> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: PostFeedFilter.allCases,
        initialMenuSelection: .Global
    )

    var body: some View {
        ContentScrollView(
            postViewEitherSupplier: postViewEitherSupplier
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
                postFeedFilterDropDownMenuView: postFeedFilterDropDownMenu.view
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
