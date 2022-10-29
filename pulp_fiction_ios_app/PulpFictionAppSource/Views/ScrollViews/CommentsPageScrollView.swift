//
//  CommentsPageScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// View that scrolls through the comments page for a post
struct CommentsPageScrollView: View {
    let imagePostView: ImagePostView
    let postFeedMessenger: PostFeedMessenger

    var body: some View {
        TopNavigationBarView(topNavigationBarViewBuilder: { CommentsPageTopNavigationBar() }) {
            ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<CommentView> in
                postFeedMessenger
                    .getCommentFeed(postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId)
                    .makeIterator()
            }
        }
    }
}
