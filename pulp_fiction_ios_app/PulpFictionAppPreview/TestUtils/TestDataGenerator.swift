//
//  TestDataGenerator.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//

import Bow
import Foundation
import PulpFictionAppSource
import SwiftProtobuf
import UIKit

public struct FakeData {
    static let caption = "test caption please ignore"
    static let imageUrl = "https://angelfire.com/never_gonna_give_you_up.jpg"
    static let userAvatarJpgName = "Shadowfax"
    static let imagePostJpgName = "Rickroll"
    static let postCreatorDisplayName = "ShadowFax"
}

public extension UserMetadataProto {
    static func generate() -> UserMetadataProto {
        UserMetadataProto.with{
            $0.userID = UUID().uuidString
            $0.displayName = FakeData.postCreatorDisplayName
            $0.createdAt = Google_Protobuf_Timestamp.with {
                $0.seconds = 0
                $0.nanos = 0
            }
            $0.avatarImageURL = FakeData.imageUrl
        }
    }
}

public extension Post.PostMetadata {
    static func generate(_ postType: Post.PostType) -> Post.PostMetadata {
        Post.PostMetadata.with {
            $0.postID = UUID().uuidString
            $0.createdAt = Google_Protobuf_Timestamp.with {
                $0.seconds = 0
                $0.nanos = 0
            }
            $0.postType = postType
            $0.postState = Post.PostState.created
            $0.postCreatorMetadata = UserMetadataProto.generate()
        }
    }
}

public extension Post.ImagePost {
    static func generate() -> Post.ImagePost {
        Post.ImagePost.with {
            $0.caption = FakeData.caption
            $0.imageURL = FakeData.imageUrl
        }
    }
}

public extension Post {
    static func generate(_ postType: Post.PostType) -> Post {
        Post.with {
            $0.metadata = Post.PostMetadata.generate(postType)
            switch postType {
            case .image:
                $0.imagePost = Post.ImagePost.generate()
            default: break
            }
        }
    }
}

public extension ImagePostData {
    class ErrorBuildingUIImage: PulpFictionRequestError {}
    class ErrorBuildingPostUIImage: ErrorBuildingUIImage {}
    class ErrorBuildingUserAvatarUIImage: ErrorBuildingUIImage {}
    
    static func generate() -> Either<PulpFictionRequestError, ImagePostData> {
        let postProto = Post.generate(Post.PostType.image)
        
        let serializePostImageResult = Either<PulpFictionRequestError, Data>.var()
        let serializeUserAvatarImageResult = Either<PulpFictionRequestError, Data>.var()
        let buildPostMetadataResult = Either<PulpFictionRequestError, PostMetadata>.var()
        return binding(
            serializePostImageResult <- UIImage
                .fromBundleFile(named: FakeData.imagePostJpgName)
                .toEither(ErrorBuildingPostUIImage())
                .flatMap{$0.serializeImage()},
            serializeUserAvatarImageResult <- UIImage
                .fromBundleFile(named: FakeData.userAvatarJpgName)
                .toEither(ErrorBuildingUserAvatarUIImage())
                .flatMap{$0.serializeImage()},
            buildPostMetadataResult <- postProto
                .metadata
                .toPostMetadata(serializeUserAvatarImageResult.get),
            yield: postProto
                .imagePost
                .toPostData(buildPostMetadataResult.get, serializePostImageResult.get)
        )^
    }
}
