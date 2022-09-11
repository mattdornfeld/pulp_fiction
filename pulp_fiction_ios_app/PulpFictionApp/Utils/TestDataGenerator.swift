//
//  TestDataGenerator.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//

import Bow
import Foundation
import SwiftProtobuf

public enum FakeData {
    static let caption = "test caption please ignore"
    static let imageUrl = "https://angelfire.com/never_gonna_give_you_up.jpg"
}

public extension Post.PostMetadata {
    static func generate(_ postType: Post.PostType) -> Post.PostMetadata {
        Post.PostMetadata.with {
            $0.postID = UUID().uuidString
            $0.createdAt = Google_Protobuf_Timestamp.with {
                $0.seconds = 0
                $0.nanos = 0
            }
            $0.postCreatorID = UUID().uuidString
            $0.postType = postType
            $0.postState = Post.PostState.created
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
    static func generate() -> Either<PulpFictionRequestError, ImagePostData> {
        let postProto = Post.generate(Post.PostType.image)
        return try postProto
            .imagePost
            .toPostData(postProto.metadata)
    }
}
