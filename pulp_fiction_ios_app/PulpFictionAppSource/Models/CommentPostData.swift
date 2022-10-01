//
//  CommentPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Foundation

/// Comment post data is stored in this model. Used for rendering CommentView.
public struct CommentPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: PostUpdateIdentifier
    public let postMetadata: PostMetadata

    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.commentPostData(self)
    }
}

public extension CommentPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
}

public extension Post.Comment {
    func toPostData(_ postMetadata: PostMetadata) -> CommentPostData {
        CommentPostData(postMetadata)
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.comment(self)
        }
    }
}
