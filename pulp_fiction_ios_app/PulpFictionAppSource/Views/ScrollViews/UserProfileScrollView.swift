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
    private let postScrollViewBuilder: ScrollableContentViewBuilder<ImagePostView>
    @ViewBuilder private let userProfileViewBuilder: () -> Content
    private let userPostData: UserPostData

    init(
        userPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        userProfileViewBuilder: @escaping () -> Content
    ) {
        postScrollViewBuilder = ScrollableContentViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getUserProfilePostFeed(userId: userPostData.userId)
                .makeIterator()
        }
        self.userProfileViewBuilder = userProfileViewBuilder
        self.userPostData = userPostData
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { UserProfileTopNavigationBar(userPostData: userPostData) }) {
            postScrollViewBuilder.buildView(.some(userProfileViewBuilder()))
        }
    }
}
