//
//  PostData.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/7/22.
//
import Bow
import Foundation
import UIKit

public struct PostMetadata: Codable, Equatable, Identifiable {
    public let id: UUID
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
    
    public init(_ postId: UUID, _ postCreatorId: UUID, _ postType: Post.PostType, _ postState: Post.PostState) {
        self.id = postId
        self.postId = postId
        self.postCreatorId = postCreatorId
        self.postType = postType
        self.postState = postState
    }

    public init(_ postMetadataProto: Post.PostMetadata) {
        self.init(
            UUID(uuidString: postMetadataProto.postID)!,
            UUID(uuidString: postMetadataProto.postCreatorID)!,
            postMetadataProto.postType,
            postMetadataProto.postState
        )
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postTypeRawValue = try values.decode(Int.self, forKey: .postType)
        let postStateRawValue = try values.decode(Int.self, forKey: .postState)
        
        self.init(
            try UUID(uuidString: values.decode(String.self, forKey: .postId))!,
            try UUID(uuidString: values.decode(String.self, forKey: .postCreatorId))!,
            Post.PostType(rawValue: postTypeRawValue) ?? Post.PostType.UNRECOGNIZED(postTypeRawValue),
            Post.PostState(rawValue: postStateRawValue) ?? Post.PostState.UNRECOGNIZED(postStateRawValue)
        )
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

public protocol PostDataIdentifiable: Identifiable {
}

public struct ImagePostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let caption: String
    public let imageUrl: String
    public let imageJpg: Data
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.imagePostData(self)
    }
}

public extension ImagePostData {
    init(_ postMetadataProto: Post.PostMetadata, _ imagePostProto: Post.ImagePost) {
        let postMetadata = postMetadataProto.toPostMetadata()
        self.init(
            id: postMetadata.id,
            caption: imagePostProto.caption,
            imageUrl: imagePostProto.imageURL,
            imageJpg: Data(),
            postMetadata: postMetadata
        )
    }
    
    /** Temporary method used for development
     */
    init(_ createImagePostRequestProto: CreatePostRequest.CreateImagePostRequest) {
        let postMetadata = PostMetadata(
            UUID(),
            UUID(),
            Post.PostType.image,
            Post.PostState.created
        )
        self.init(
            id: postMetadata.id,
            caption: createImagePostRequestProto.caption,
            imageUrl: "",
            imageJpg: createImagePostRequestProto.imageJpg,
            postMetadata: postMetadata
        )
    }
}

public struct CommentPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.commentPostData(self)
    }
}

public extension CommentPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
    
    init(_ postMetadataProto: Post.PostMetadata, _ commentProto: Post.Comment) {
        self.init(postMetadataProto.toPostMetadata())
    }
}

public struct UserPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
}

public extension UserPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
    
    init(_ postMetadataProto: Post.PostMetadata, _ userPostProto: Post.UserPost) {
        self.init(postMetadataProto.toPostMetadata())
    }
}

public struct UnrecognizedPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.unregonizedPostData(self)
    }
}

public extension UnrecognizedPostData {
    init(_ postMetadataProto: Post.PostMetadata) {
        self.postMetadata = postMetadataProto.toPostMetadata()
        self.id = self.postMetadata.id
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
