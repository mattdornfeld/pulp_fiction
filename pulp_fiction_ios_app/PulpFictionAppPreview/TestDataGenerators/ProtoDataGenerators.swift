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
    static let imagePostJpgUrl = try! URL(string: "https://firstorderlabs.com/rickroll.jpg").getOrThrow()
    static let userAvatarJpgUrl = try! URL(string: "https://firstorderlabs.com/shadowfax.jpg").getOrThrow()
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
            $0.avatarImageURL = FakeData.userAvatarJpgUrl.absoluteString
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
            $0.postUpdateIdentifier = Post.PostUpdateIdentifier.with {
                $0.postID = UUID().uuidString
                $0.updatedAt = Google_Protobuf_Timestamp.with {
                    $0.seconds = 0
                    $0.nanos = 0
                }
            }
            $0.postType = postType
            $0.postState = Post.PostState.created
            $0.postCreatorID = UUID().uuidString
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
            $0.imageURL = FakeData.imagePostJpgUrl.absoluteString
            $0.interactionAggregates = Post.InteractionAggregates.generate()
            $0.postCreatorLatestUserPost = Post.UserPost.generate().toPost(Post.PostMetadata.generate(Post.PostType.user))
        }
    }
}

public extension Post.Comment {
    static func generate() -> Post.Comment {
        Post.Comment.with {
            $0.body = FakeData.comment
            $0.postCreatorLatestUserPost = Post.UserPost.generate().toPost(Post.PostMetadata.generate(Post.PostType.user))
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
