//
//  TestDataGenerator.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//

import PulpFictionApp
import Foundation
import SwiftProtobuf

struct FakeData {
    static let caption = "test caption please ignore"
    static let imageUrl = "https://angelfire.com/never_gonna_give_you_up.jpg"
}

protocol TestDataGenerator {
}

extension Post.PostMetadata: TestDataGenerator {
    static func generate(_ postType: Post.PostType) -> Post.PostMetadata {
        Post.PostMetadata.with{
            $0.postID = UUID().uuidString
            $0.createdAt = Google_Protobuf_Timestamp.with {
                $0.seconds = 0
                $0.nanos = 0
            }
            $0.postCreatorID =  UUID().uuidString
            $0.postType = postType
            $0.postState = Post.PostState.created
        }
    }
}

extension Post.ImagePost: TestDataGenerator {
    static func generate() -> Post.ImagePost {
        Post.ImagePost.with{
            $0.caption = FakeData.caption
            $0.imageURL = FakeData.imageUrl
        }
    }
}

extension Post: TestDataGenerator {
    static func generate(_ postType: Post.PostType) -> Post {
        Post.with{
            $0.metadata = Post.PostMetadata.generate(postType)
            switch postType {
            case .image:
                $0.imagePost = Post.ImagePost.generate()
            default: break
            }
        }
    }
}

extension ImagePostData: TestDataGenerator {
    static func generate() throws -> ImagePostData {
        let postProto = Post.generate(Post.PostType.image)
        
        return try postProto
            .imagePost
            .toPostData(postProto.metadata)
            .getOrThrow()
    }
}
