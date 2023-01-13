//
//  LoggedInUserProfileScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//
import ComposableArchitecture
import Foundation
import SwiftUI

/// View that scrolls through the logged in user's profile along with their posts
struct LoggedInUserProfileScrollView<Content: View>: ScrollViewParent {
    let loggedInUserPostData: UserPostData
    let externalMessengers: ExternalMessengers
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        ContentScrollView(
            prependToBeginningOfScroll: userProfileViewBuilder(),
            externalMessengers: externalMessengers,
            notificationBannerViewStore: notificationBannerViewStore
        ) { viewStore in
            postFeedMessenger
                .getUserProfilePostFeed(
                    userId: loggedInUserPostData.userId,
                    viewStore: viewStore
                )
        }

        .toolbar {
            LoggedInUserProfileTopNavigationBar(
                loggedInUserPostData: loggedInUserPostData,
                externalMessengers: externalMessengers,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
    }
}
