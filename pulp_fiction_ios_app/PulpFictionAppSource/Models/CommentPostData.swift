//
//  CommentPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import Foundation

/// Comment post data is stored in this model. Used for rendering CommentView.
public struct CommentPostData: PostData, PostDataIdentifiable, Equatable {
    public let body: String
    public let id: PostUpdateIdentifier
    public let parentPostId: UUID
    public let postMetadata: PostMetadata
    public let postInteractionAggregates: PostInteractionAggregates

    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.commentPostData(self)
    }

    public static func create(_ postMetadata: PostMetadata, _ commentProto: Post.Comment) -> Either<PulpFictionRequestError, CommentPostData> {
        commentProto.parentPostID.toUUID().mapRight { parentPostId in
            CommentPostData(
                body: commentProto.body,
                id: postMetadata.postUpdateIdentifier,
                parentPostId: parentPostId,
                postMetadata: postMetadata,
                postInteractionAggregates: commentProto.interactionAggregates.toPostInteractionAggregates()
            )
        }
    }
}

public extension Post.Comment {
    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.comment(self)
        }
    }
}
