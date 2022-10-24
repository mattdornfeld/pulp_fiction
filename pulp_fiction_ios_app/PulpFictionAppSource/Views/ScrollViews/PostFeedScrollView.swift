//
//  PostFeedScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// View that scrolls through a feed of posts
struct PostFeedScrollView: View {
    private let postScrollViewBuilder: ScrollableContentViewBuilder<ImagePostView>

    init(postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = ScrollableContentViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<ImagePostView> in
            postFeedMessenger
                .getGlobalPostFeed()
                .makeIterator()
        }
    }

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { PostFeedTopNavigationBar() }) {
            postScrollViewBuilder.buildView()
        }
    }
}
