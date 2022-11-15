//
//  LoggedInUserProfileScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import Foundation
import SwiftUI

/// View that scrolls through the logged in user's profile along with their posts
struct LoggedInUserProfileScrollView<Content: View>: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        ContentScrollView(postFeedMessenger: postFeedMessenger, prependToBeginningOfScroll: userProfileViewBuilder()) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getUserProfilePostFeed(userId: loggedInUserPostData.userId)
                .makeIterator()
        }

        .toolbar {
            LoggedInUserProfileTopNavigationBar(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger
            )
        }
    }
}
