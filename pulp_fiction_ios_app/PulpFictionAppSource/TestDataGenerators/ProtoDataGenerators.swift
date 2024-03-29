//
//  ProtoDataGenerators.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/21/22.
//

import Bow
import Foundation
import SwiftProtobuf
import UIKit

public enum FakeData {
    public static let caption: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    public static let comment: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    public static let bio: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    public static let imagePostJpgUrl: URL = try! URL(string: "https://firstorderlabs.com/rickroll.jpg").getOrThrow()
    public static let userAvatarJpgUrl: URL = try! URL(string: "https://firstorderlabs.com/shadowfax.jpg").getOrThrow()
    public static let userAvatarJpgName: String = "Shadowfax"
    public static let imagePostJpgName: String = "Rickroll"
    public static let postCreatorDisplayName: String = "ShadowFax"
    static let expectedEmail: String = "expectedEmail@aol.com"
    static let expectedPhoneNumber: String = "212-867-5309"
    static let expectedPassword: String = "expectedPassword"
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
            $0.bio = FakeData.bio
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
        generate(parentPostId: UUID())
    }

    static func generate(parentPostId: UUID) -> Post.Comment {
        Post.Comment.with {
            $0.body = FakeData.comment
            $0.parentPostID = parentPostId.uuidString
            $0.postCreatorLatestUserPost = Post.UserPost.generate().toPost(Post.PostMetadata.generate(Post.PostType.user))
            $0.interactionAggregates = Post.InteractionAggregates.generate()
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
