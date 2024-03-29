//
//  UserPostData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import BowOptics
import Foundation
import UIKit

/// User post data is stored in this model. Used for rendering UserPostView and avatar + display name in other post views.
public class UserPostData: UserData, PostData, PostDataIdentifiable, Equatable, AutoSetter {
    public let id: PostUpdateIdentifier
    let postMetadata: PostMetadata
    var userPostContentData: ContentData
    var userDisplayName: String
    var bio: String
    let userId: UUID
    @CodableUIImage var userAvatarUIImage: UIImage

    public init(id: PostUpdateIdentifier, postMetadata: PostMetadata, userPostContentData: ContentData, userDisplayName: String, bio: String, userId: UUID, userAvatarUIImage: UIImage) {
        self.id = id
        self.postMetadata = postMetadata
        self.userPostContentData = userPostContentData
        self.userDisplayName = userDisplayName
        self.bio = bio
        self.userId = userId
        self.userAvatarUIImage = userAvatarUIImage
    }

    public static func == (lhs: UserPostData, rhs: UserPostData) -> Bool {
        lhs.id == rhs.id &&
            lhs.postMetadata == rhs.postMetadata &&
            lhs.userPostContentData == rhs.userPostContentData &&
            lhs.userDisplayName == rhs.userDisplayName &&
            lhs.bio == rhs.bio &&
            lhs.userId == rhs.userId &&
            lhs.userAvatarUIImage == rhs.userAvatarUIImage
    }

    func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
}

private extension UserPostData {
    convenience init(
        postMetadata: PostMetadata,
        userPostProto: Post.UserPost,
        userPostContentData: ContentData,
        userId: UUID,
        userAvatarUIImage: UIImage
    ) {
        self.init(
            id: postMetadata.id,
            postMetadata: postMetadata,
            userPostContentData: userPostContentData,
            userDisplayName: userPostProto.userMetadata.displayName,
            bio: userPostProto.userMetadata.bio,
            userId: userId,
            userAvatarUIImage: userAvatarUIImage
        )
    }
}

extension Post.UserPost {
    func toPostData(
        postMetadata: PostMetadata,
        userPostContentData: ContentData
    ) -> Either<PulpFictionRequestError, UserPostData> {
        let userIdEither = Either<PulpFictionRequestError, UUID>.var()
        let userAvatarUIImageEither = Either<PulpFictionRequestError, UIImage>.var()

        return binding(
            userIdEither <- userMetadata.userID.toUUID(),
            userAvatarUIImageEither <- userPostContentData.toUIImage(),
            yield: UserPostData(
                postMetadata: postMetadata,
                userPostProto: self,
                userPostContentData: userPostContentData,
                userId: userIdEither.get,
                userAvatarUIImage: userAvatarUIImageEither.get
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
