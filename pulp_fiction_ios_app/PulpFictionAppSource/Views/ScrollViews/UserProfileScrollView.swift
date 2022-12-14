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
    let userProfileOwnerPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ViewBuilder let userProfileViewBuilder: () -> Content

    var body: some View {
        ContentScrollView(postFeedMessenger: postFeedMessenger, prependToBeginningOfScroll: userProfileViewBuilder()) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getUserProfilePostFeed(userId: userProfileOwnerPostData.userId)
                .makeIterator()
        }

        .toolbar {
            UserProfileTopNavigationBar(
                userProfileOwnerPostData: userProfileOwnerPostData,
                postFeedMessenger: postFeedMessenger
            )
        }
    }
}
