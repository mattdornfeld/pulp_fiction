//
//  UserConnectionsScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// View thay scrolls through a user's connections (e.g. their followers and followees)
struct UserConnectionsScrollView: View {
    private let postScrollViewBuilder: ScrollableContentViewBuilder<UserConnectionView>

    init(
        userId: UUID,
        postFeedMessenger: PostFeedMessenger
    ) {
        postScrollViewBuilder = ScrollableContentViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<UserConnectionView> in
            postFeedMessenger
                .getFollowedScrollFeed(userId: userId)
                .makeIterator()
        }
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { UserConnectionsTopNavigationBar() }) {
            postScrollViewBuilder.buildView()
        }
    }
}
