//
//  UserProfileScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// View that scrolls through a user's profile along with their posts
struct UserProfileScrollView<Content: View>: View {
    let userPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { UserProfileTopNavigationBar(userPostData: userPostData) }) {
            ContentScrollView(postFeedMessenger: postFeedMessenger, prependToBeginningOfScroll: userProfileViewBuilder()) { () -> PostViewFeedIterator<ImagePostView> in
                postFeedMessenger
                    .getUserProfilePostFeed(userId: userPostData.userId)
                    .makeIterator()
            }
        }
    }
}
