//
//  CommentPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import Foundation

/// Comment post data is stored in this model. Used for rendering CommentView.
class CommentPostData: PostData, PostDataIdentifiable, Equatable {
    let body: String
    let id: PostUpdateIdentifier
    let parentPostId: UUID
    let postMetadata: PostMetadata
    let postInteractionAggregates: PostInteractionAggregates
    let loggedInUserPostInteractions: LoggedInUserPostInteractions

    init(body: String, id: PostUpdateIdentifier, parentPostId: UUID, postMetadata: PostMetadata, postInteractionAggregates: PostInteractionAggregates, loggedInUserPostInteractions: LoggedInUserPostInteractions) {
        self.body = body
        self.id = id
        self.parentPostId = parentPostId
        self.postMetadata = postMetadata
        self.postInteractionAggregates = postInteractionAggregates
        self.loggedInUserPostInteractions = loggedInUserPostInteractions
    }

    static func == (lhs: CommentPostData, rhs: CommentPostData) -> Bool {
        lhs.body == rhs.body &&
            lhs.id == rhs.id &&
            lhs.parentPostId == rhs.parentPostId &&
            lhs.postMetadata == rhs.postMetadata &&
            lhs.postInteractionAggregates == rhs.postInteractionAggregates &&
            lhs.loggedInUserPostInteractions == rhs.loggedInUserPostInteractions
    }

    func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.commentPostData(self)
    }

    static func create(_ postMetadata: PostMetadata, _ commentProto: Post.Comment) -> Either<PulpFictionRequestError, CommentPostData> {
        commentProto.parentPostID.toUUID().mapRight { parentPostId in
            CommentPostData(
                body: commentProto.body,
                id: postMetadata.postUpdateIdentifier,
                parentPostId: parentPostId,
                postMetadata: postMetadata,
                postInteractionAggregates: commentProto
                    .interactionAggregates
                    .toPostInteractionAggregates(),
                loggedInUserPostInteractions: commentProto
                    .loggedInUserPostInteractions
                    .toLoggedInUserPostInteractions()
            )
        }
    }
}

extension Post.Comment {
    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.comment(self)
        }
    }
}
