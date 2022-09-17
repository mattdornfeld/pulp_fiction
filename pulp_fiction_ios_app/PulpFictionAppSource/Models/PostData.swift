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
    public let postType: Post.PostType
    public let postState: Post.PostState
    public let createdAt: Date
    public let postCreatorMetadata: UserMetadata

    private enum CodingKeys: String, CodingKey {
        case postId
        case postType
        case postState
        case createdAt
    }

    public init(
        _ postId: UUID,
        _ postType: Post.PostType,
        _ postState: Post.PostState,
        _ createdAt: Date,
        _ userMetadata: UserMetadata
    ) {
        id = postId
        self.postId = postId
        self.postType = postType
        self.postState = postState
        self.createdAt = createdAt
        postCreatorMetadata = userMetadata
    }

    public static func create(_ postMetadataProto: Post.PostMetadata, _ avatarImageJpg: Data) -> Either<PulpFictionRequestError, PostMetadata> {
        let parsePostIdResult = Either<PulpFictionRequestError, UUID>.var()
        let createUserMetadataResult = Either<PulpFictionRequestError, UserMetadata>.var()

        return binding(
            parsePostIdResult <- postMetadataProto.postID.toUUID(),
            createUserMetadataResult <- UserMetadata.create(postMetadataProto.postCreatorMetadata, avatarImageJpg),
            yield: PostMetadata(
                parsePostIdResult.get,
                postMetadataProto.postType,
                postMetadataProto.postState,
                postMetadataProto.createdAt.date,
                createUserMetadataResult.get
            )
        )^
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postTypeRawValue = try values.decode(Int.self, forKey: .postType)
        let postStateRawValue = try values.decode(Int.self, forKey: .postState)

        self.init(
            try UUID(uuidString: values.decode(String.self, forKey: .postId)).getOrThrow(),
            Post.PostType(rawValue: postTypeRawValue) ?? Post.PostType.UNRECOGNIZED(postTypeRawValue),
            Post.PostState(rawValue: postStateRawValue) ?? Post.PostState.UNRECOGNIZED(postStateRawValue),
            try values.decode(Date.self, forKey: .createdAt),
            try UserMetadata(from: decoder)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(postId.uuidString, forKey: .postId)
        try container.encode(postType.rawValue, forKey: .postType)
        try container.encode(postState.rawValue, forKey: .postState)
        try postCreatorMetadata.encode(to: encoder)
    }
}

public protocol PostData: Codable {
    var postMetadata: PostMetadata { get }

    func toPostDataOneOf() -> PostDataOneOf
}

public protocol PostDataIdentifiable: Identifiable {}

public struct ImagePostData: PostData, PostDataIdentifiable, Equatable {
    public let id: UUID
    public let caption: String
    public let imageUrl: String
    public let imageJpg: Data
    public let postMetadata: PostMetadata

    public func toPostDataOneOf() -> PostDataOneOf {
        PostDataOneOf.imagePostData(self)
    }

//    static func create(_ postMetadata: PostMetadata, _ imagePostProto: Post.ImagePost, _ imageJpg: Data) -> Either<PulpFictionRequestError, ImagePostData> {
//        PostMetadata.create(postMetadataProto).mapRight { postMetadata in ImagePostData(postMetadata, imagePostProto, imageJpg) }
//    }
}

public extension ImagePostData {
    init(_ postMetadata: PostMetadata, _ imagePostProto: Post.ImagePost, _ imageJpg: Data) {
        self.init(
            id: postMetadata.id,
            caption: imagePostProto.caption,
            imageUrl: imagePostProto.imageURL,
            imageJpg: imageJpg,
            postMetadata: postMetadata
        )
    }

    /** Temporary method used for development
     */
    init(_ createImagePostRequestProto: CreatePostRequest.CreateImagePostRequest) {
        let userMetadata = UserMetadata(
            id: UUID(),
            userId: UUID(),
            displayName: "ShadowFax",
            avatarImageUrl: "",
            createdAt: Date(),
            avatarImageJpg: Data()
        )

        let postMetadata = PostMetadata(
            UUID(),
            Post.PostType.image,
            Post.PostState.created,
            Date.now,
            userMetadata
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

//    static func create(_ postMetadata: PostMetadata, _: Post.Comment) -> Either<PulpFictionRequestError, CommentPostData> {
//        PostMetadata.create(postMetadataProto, avatarImageJpg).mapRight { postMetadata in CommentPostData(postMetadata) }
//    }
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

//    static func create(_ postMetadataProto: Post.PostMetadata, _: Post.UserPost) -> Either<PulpFictionRequestError, UserPostData> {
//        PostMetadata.create(postMetadataProto).mapRight { postMetadata in UserPostData(postMetadata) }
//    }
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
