//
//  ProtoDataGenerators.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import Foundation
import PulpFictionAppSource
import SwiftProtobuf
import UIKit

public enum FakeData {
    static let caption = "test caption please ignore"
    static let comment = "test comment please ignore"
    static let imageUrl = "https://angelfire.com/never_gonna_give_you_up.jpg"
    static let userAvatarJpgName = "Shadowfax"
    static let imagePostJpgName = "Rickroll"
    static let postCreatorDisplayName = "ShadowFax"
}

public extension UserMetadataProto {
    static func generate() -> UserMetadataProto {
        UserMetadataProto.with {
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

public extension Post {
    static func generate(_ postType: Post.PostType) -> Post {
        let postMetadata = Post.PostMetadata.generate(postType)
        switch postType {
        case .image:
            return Post.ImagePost.generate().toPost(postMetadata)
        case .comment:
            return Post.Comment.generate().toPost(postMetadata)
        case .user:
            return Post.UserPost.generate().toPost(postMetadata)
        case .UNRECOGNIZED:
            return Post()
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

public extension Post.InteractionAggregates {
    static func generate() -> Post.InteractionAggregates {
        Post.InteractionAggregates.with {
            $0.numLikes = Int64.random(in: 0 ..< 10000)
            $0.numDislikes = Int64.random(in: 0 ..< 10000)
            $0.numChildComments = Int64.random(in: 0 ..< 10000)
        }
    }
}

public extension Post.ImagePost {
    static func generate() -> Post.ImagePost {
        Post.ImagePost.with {
            $0.caption = FakeData.caption
            $0.imageURL = FakeData.imageUrl
            $0.interactionAggregates = Post.InteractionAggregates.generate()
        }
    }
}

public extension Post.Comment {
    static func generate() -> Post.Comment {
        Post.Comment.with {
            $0.body = FakeData.comment
        }
    }
}

public extension Post.UserPost {
    static func generate() -> Post.UserPost {
        Post.UserPost.with {
            $0.userMetadata = UserMetadataProto.generate()
        }
    }
}
