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
    private let postScrollViewBuilder: ScrollableContentViewBuilder<CommentView>
    private let imagePostView: ImagePostView

    init(imagePostView: ImagePostView, postFeedMessenger: PostFeedMessenger) {
        postScrollViewBuilder = ScrollableContentViewBuilder(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<CommentView> in
            postFeedMessenger
                .getCommentFeed(postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId)
                .makeIterator()
        }
        self.imagePostView = imagePostView
    }

    var body: some View {
        postScrollViewBuilder.buildView(.some(
            VStack {
                imagePostView
                Divider()
                Caption("\(imagePostView.imagePostData.postInteractionAggregates.numChildComments.formatAsStringForView()) Comments")
                    .foregroundColor(.gray)
            })
        )
    }
}
