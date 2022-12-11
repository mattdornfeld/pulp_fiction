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
struct LoggedInUserProfileScrollView<Content: View>: ImagePostScrollView {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        ContentScrollView(
            prependToBeginningOfScroll: userProfileViewBuilder(),
            postViewEitherSupplier: postViewEitherSupplier
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
                postFeedMessenger: postFeedMessenger
            )
        }
    }
}
