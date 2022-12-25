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
    let postMetadata: PostMetadata
    let backendMessenger: BackendMessenger
    let notificationnotificationBannerViewStore: NotificationnotificationBannerViewStore

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
            ).navigateOnTap(destination: CommentCreator(
                postMetadata: postMetadata,
                backendMessenger: backendMessenger,
                notificationnotificationBannerViewStore: notificationnotificationBannerViewStore
            ))
        }
    }
}

/// View that scrolls through the comments page for a post
struct CommentsPageScrollView: ScrollViewParent {
    let imagePostView: ImagePostView
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore

    init(
        imagePostView: ImagePostView,
        externalMessengers: ExternalMessengers,
        notificationBannerViewStore: NotificationnotificationBannerViewStore
    ) {
        self.imagePostView = imagePostView
        self.externalMessengers = externalMessengers
        self.notificationBannerViewStore = notificationBannerViewStore
    }

    var body: some View {
        ContentScrollView(
            externalMessengers: externalMessengers,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            postFeedMessenger
                .getCommentFeed(
                    postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId,
                    viewStore: viewStore
                )
        }.toolbar {
            CommentsPageTopNavigationBar(
                postMetadata: imagePostView.postMetadata,
                backendMessenger: backendMessenger,
                notificationnotificationBannerViewStore: notificationBannerViewStore
            )
        }
    }
}
