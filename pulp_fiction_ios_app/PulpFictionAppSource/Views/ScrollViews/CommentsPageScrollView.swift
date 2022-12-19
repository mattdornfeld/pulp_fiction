//
//  CommentsPageScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//
import Bow
import ComposableArchitecture
import Foundation
import SwiftUI

/// Navigation bar for CommentsPageScrollView
struct CommentsPageTopNavigationBar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Comments")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Symbol(
                symbolName: "plus",
                size: 20,
                color: .gray
            ).navigateOnTap(destination: CommentCreatorView())
        }
    }
}

/// View that scrolls through the comments page for a post
struct CommentsPageScrollView: ScrollViewParent {
    let imagePostView: ImagePostView
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    init(
        imagePostView: ImagePostView,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.imagePostView = imagePostView
        self.postFeedMessenger = postFeedMessenger
        self.backendMessenger = backendMessenger
        self.notificationBannerViewStore = notificationBannerViewStore
    }

    var body: some View {
        ContentScrollView(
            postFeedMessenger: postFeedMessenger,
            backendMessenger: backendMessenger,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            postFeedMessenger
                .getCommentFeed(
                    postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId,
                    viewStore: viewStore
                )
        }.toolbar {
            CommentsPageTopNavigationBar()
        }
    }
}
