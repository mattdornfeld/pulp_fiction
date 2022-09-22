//
//  ProtoExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/18/22.
//

import Bow
import Foundation

public extension Post.PostMetadata {
    func toPostMetadata(_ avatarImageJpg: Data) -> Either<PulpFictionRequestError, PostMetadata> {
        PostMetadata.create(self, avatarImageJpg)
    }
}

public extension CreatePostRequest {
    static func createImagePostRequest(_ caption: String, _ imageJpg: Data) -> CreatePostRequest {
        CreatePostRequest.with {
            $0.createImagePostRequest = CreatePostRequest.CreateImagePostRequest.with {
                $0.caption = caption
                $0.imageJpg = imageJpg
            }
        }
    }
}

public extension Post.ImagePost {
    func toPostData(_ postMetadata: PostMetadata, _ imageJpg: Data) -> ImagePostData {
        ImagePostData(postMetadata, self, imageJpg)
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.imagePost(self)
        }
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

public extension Post.UserPost {
    func toPostData(_ postMetadata: PostMetadata, _: Data) -> UserPostData {
        UserPostData(postMetadata)
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.userPost(self)
        }
    }
}

public extension Post.InteractionAggregates {
    func toPostInteractionAggregates() -> PostInteractionAggregates {
        PostInteractionAggregates(
            numLikes: numLikes,
            numDislikes: numDislikes,
            numChildComments: numChildComments
        )
    }
}
