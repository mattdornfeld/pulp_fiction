//
//  PostData.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/7/22.
//
import Bow
import Foundation

public struct PostMetadata: Codable, Equatable {
    public let postId: UUID
    public let postCreatorId: UUID
    public let postType: Post.PostType
    public let postState: Post.PostState

    private enum CodingKeys: String, CodingKey {
        case postId
        case postCreatorId
        case postType
        case postState
    }

    public init(_ postMetadataProto: Post.PostMetadata) {
        postId = UUID.fromDatatypeValue(postMetadataProto.postID)
        postCreatorId = UUID.fromDatatypeValue(postMetadataProto.postCreatorID)
        postType = postMetadataProto.postType
        postState = postMetadataProto.postState
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postTypeRawValue = try values.decode(Int.self, forKey: .postType)
        let postStateRawValue = try values.decode(Int.self, forKey: .postState)

        postId = try UUID.fromDatatypeValue(values.decode(String.self, forKey: .postId))
        postCreatorId = try UUID.fromDatatypeValue(values.decode(String.self, forKey: .postCreatorId))
        postType = Post.PostType(rawValue: postTypeRawValue) ?? Post.PostType.UNRECOGNIZED(postTypeRawValue)
        postState = Post.PostState(rawValue: postStateRawValue) ?? Post.PostState.UNRECOGNIZED(postStateRawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(postId.uuidString, forKey: .postId)
        try container.encode(postCreatorId.uuidString, forKey: .postCreatorId)
        try container.encode(postType.rawValue, forKey: .postType)
        try container.encode(postState.rawValue, forKey: .postState)
    }
}

public protocol PostData: Codable {
    var postMetadata: PostMetadata { get }
    
    func toPostDataOneOf() -> PostDataOneOf
}

public struct ImagePostData: PostData, Equatable {
    let caption: String
    let imageUrl: String
    let image: Data
    public let postMetadata: PostMetadata
    
    public init(_ postMetadataProto: Post.PostMetadata, _ imagePostProto: Post.ImagePost) {
        self.caption = imagePostProto.caption
        self.imageUrl = imagePostProto.imageURL
        self.image = Data()
        self.postMetadata = postMetadataProto.toPostMetadata()
    }
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.imagePostData(self)
    }
}

public struct CommentPostData: PostData, Equatable {
    public let postMetadata: PostMetadata
    
    public init(_ postMetadataProto: Post.PostMetadata, _ imagePostProto: Post.Comment) {
        self.postMetadata = postMetadataProto.toPostMetadata()
    }
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.commentPostData(self)
    }
}

public struct UserPostData: PostData, Equatable {
    public let postMetadata: PostMetadata
    
    public init(_ postMetadataProto: Post.PostMetadata, _ imagePostProto: Post.UserPost) {
        self.postMetadata = postMetadataProto.toPostMetadata()
    }
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
}

public struct UnrecognizedPostData: PostData, Equatable {
    public let postMetadata: PostMetadata
    
    public init(_ postMetadataProto: Post.PostMetadata) {
        self.postMetadata = postMetadataProto.toPostMetadata()
    }
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.unregonizedPostData(self)
    }
}

public enum PostDataOneOf: Codable, Equatable {
    case unregonizedPostData(UnrecognizedPostData)
    case imagePostData(ImagePostData)
    case commentPostData(CommentPostData)
    case userPostData(UserPostData)

    public func toPostData() -> PostData {
        switch self {
        case let .unregonizedPostData(unrecognizedPostData):
            return unrecognizedPostData
        case let .imagePostData(imagePostData):
            return imagePostData
        case let .commentPostData(commentPostData):
            return commentPostData
        case let .userPostData(userPostData):
            return userPostData
        }
    }
}
