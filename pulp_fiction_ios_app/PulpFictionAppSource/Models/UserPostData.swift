//
//  UserPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Foundation

/// User post data is stored in this model. Used for rendering UserPostView and avatar + display name in other post views.
public struct UserPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: PostUpdateIdentifier
    public let postMetadata: PostMetadata
    public let userPostContentData: ContentData
    public let userDisplayName: String

    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
}

public extension UserPostData {
    init(_ postMetadata: PostMetadata, _ userPostProto: Post.UserPost, _ userPostContentData: ContentData) {
        self.init(
            id: postMetadata.id,
            postMetadata: postMetadata,
            userPostContentData: userPostContentData,
            userDisplayName: userPostProto.userMetadata.displayName
        )
    }
}

public extension Post.UserPost {
    func toPostData(_ postMetadata: PostMetadata, _ userPostContentData: ContentData) -> UserPostData {
        UserPostData(postMetadata, self, userPostContentData)
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.userPost(self)
        }
    }
}
