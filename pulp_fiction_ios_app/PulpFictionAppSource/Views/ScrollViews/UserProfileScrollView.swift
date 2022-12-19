//
//  UserProfileScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// View that scrolls through a user's profile along with their posts
struct UserProfileScrollView<Content: View>: ScrollViewParent {
    let userProfileOwnerPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        ContentScrollView(
            prependToBeginningOfScroll: userProfileViewBuilder(),
            postFeedMessenger: postFeedMessenger,
            backendMessenger: backendMessenger,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            postFeedMessenger
                .getUserProfilePostFeed(
                    userId: userProfileOwnerPostData.userId,
                    viewStore: viewStore
                )
        }

        .toolbar {
            UserProfileTopNavigationBar(
                userProfileOwnerPostData: userProfileOwnerPostData,
                postFeedMessenger: postFeedMessenger
            )
        }
    }
}
