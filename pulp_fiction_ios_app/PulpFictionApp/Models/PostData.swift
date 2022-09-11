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

    public static func create(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, PostMetadata> {
        let parsePostIdResult = Either<PulpFictionRequestError, UUID>.var()
        let parsePostCreatorIdResult = Either<PulpFictionRequestError, UUID>.var()
        
        return binding(
            parsePostIdResult <- postMetadataProto.postID.toUUID(),
            parsePostCreatorIdResult <- postMetadataProto.postCreatorID.toUUID(),
            yield: PostMetadata(
                parsePostIdResult.get,
                parsePostCreatorIdResult.get,
                postMetadataProto.postType,
                postMetadataProto.postState
            )
        )^
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postTypeRawValue = try values.decode(Int.self, forKey: .postType)
        let postStateRawValue = try values.decode(Int.self, forKey: .postState)
        
        self.init(
            try UUID(uuidString: values.decode(String.self, forKey: .postId)).getOrThrow(),
            try UUID(uuidString: values.decode(String.self, forKey: .postCreatorId)).getOrThrow(),
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
    
    static func create(_ postMetadataProto: Post.PostMetadata, _ imagePostProto: Post.ImagePost) -> Either<PulpFictionRequestError, ImagePostData> {
        PostMetadata.create(postMetadataProto).mapRight{postMetadata in ImagePostData(postMetadata, imagePostProto)}
    }
}

public extension ImagePostData {
    init(_ postMetadata: PostMetadata, _ imagePostProto: Post.ImagePost) {
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
    
    static func create(_ postMetadataProto: Post.PostMetadata, _ commentProto: Post.Comment) -> Either<PulpFictionRequestError, CommentPostData> {
        PostMetadata.create(postMetadataProto).mapRight{postMetadata in CommentPostData(postMetadata)}
    }
}

public extension CommentPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
}

public struct UserPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.userPostData(self)
    }
    
    static func create(_ postMetadataProto: Post.PostMetadata, _ userPostProto: Post.UserPost) -> Either<PulpFictionRequestError, UserPostData> {
        PostMetadata.create(postMetadataProto).mapRight{postMetadata in UserPostData(postMetadata)}
    }
}

public extension UserPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
    }
}

public struct UnrecognizedPostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let postMetadata: PostMetadata
    
    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.unregonizedPostData(self)
    }
    
    static func create(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, UnrecognizedPostData> {
        PostMetadata.create(postMetadataProto).mapRight{postMetadata in UnrecognizedPostData(postMetadata)}
    }
}

public extension UnrecognizedPostData {
    init(_ postMetadata: PostMetadata) {
        self.init(id: postMetadata.id, postMetadata: postMetadata)
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
