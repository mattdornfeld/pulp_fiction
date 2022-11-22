//
//  CommentsPageScrollView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// Navigation bar for CommentsPageScrollView
struct CommentsPageTopNavigationBar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Comments")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Symbol(
                symbolName: "plus",
                size: 20,
                color: .gray
            ).navigateOnTap(destination: CommentCreatorView())
        }
    }
}

/// View that scrolls through the comments page for a post
struct CommentsPageScrollView: View {
    let imagePostView: ImagePostView
    let postFeedMessenger: PostFeedMessenger

    var body: some View {
        ContentScrollView(postFeedMessenger: postFeedMessenger) { () -> PostViewFeedIterator<CommentView> in
            postFeedMessenger
                .getCommentFeed(postId: imagePostView.imagePostData.postMetadata.postUpdateIdentifier.postId)
                .makeIterator()
        }.toolbar {
            CommentsPageTopNavigationBar()
        }
    }
}
