//
//  UserPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import Foundation

/// User post data is stored in this model. Used for rendering UserPostView and avatar + display name in other post views.
struct UserPostData: PostData, PostDataIdentifiable, Equatable {
    let id: PostUpdateIdentifier
    let postMetadata: PostMetadata
    let userPostContentData: ContentData
    let userDisplayName: String
    let bio: String
    let userId: UUID

    func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
}

extension UserPostData {
    init(
        postMetadata: PostMetadata,
        userPostProto: Post.UserPost,
        userPostContentData: ContentData,
        userId: UUID
    ) {
        self.init(
            id: postMetadata.id,
            postMetadata: postMetadata,
            userPostContentData: userPostContentData,
            userDisplayName: userPostProto.userMetadata.displayName,
            bio: userPostProto.userMetadata.bio,
            userId: userId
        )
    }
}

extension Post.UserPost {
    func toPostData(
        postMetadata: PostMetadata,
        userPostContentData: ContentData
    ) -> Either<PulpFictionRequestError, UserPostData> {
        let userIdEither = Either<PulpFictionRequestError, UUID>.var()

        return binding(
            userIdEither <- userMetadata.userID.toUUID(),
            yield: UserPostData(
                postMetadata: postMetadata,
                userPostProto: self,
                userPostContentData: userPostContentData,
                userId: userIdEither.get
            )
        )^
    }

    func toPost(_ postMetadata: Post.PostMetadata) -> Post {
        Post.with {
            $0.metadata = postMetadata
            $0.post = Post.OneOf_Post.userPost(self)
        }
    }
}
