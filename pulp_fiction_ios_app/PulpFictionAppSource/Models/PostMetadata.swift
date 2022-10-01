//
//  PostMetadata.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import Foundation

/// Post metadata is stored in this model
public struct PostMetadata: Codable, Equatable, PostDataIdentifiable {
    public let id: PostUpdateIdentifier
    public let postUpdateIdentifier: PostUpdateIdentifier
    public let postType: Post.PostType
    public let postState: Post.PostState
    public let createdAt: Date
    public let postCreatorUserId: UUID

    private enum CodingKeys: String, CodingKey {
        case postType
        case postState
        case createdAt
        case postCreatorUserId
    }

    public init(
        PostUpdateIdentifier: PostUpdateIdentifier,
        postType: Post.PostType,
        postState: Post.PostState,
        createdAt: Date,
        postCreatorUserId: UUID
    ) {
        id = PostUpdateIdentifier
        postUpdateIdentifier = PostUpdateIdentifier
        self.postType = postType
        self.postState = postState
        self.createdAt = createdAt
        self.postCreatorUserId = postCreatorUserId
    }

    /// In the prod code path this method should be called instead of the init method since this method handles errors.
    public static func create(_ postMetadataProto: Post.PostMetadata) -> Either<PulpFictionRequestError, PostMetadata> {
        let PostUpdateIdentifierEither = Either<PulpFictionRequestError, PostUpdateIdentifier>.var()
        let postCreatorUserIdEither = Either<PulpFictionRequestError, UUID>.var()

        return binding(
            PostUpdateIdentifierEither <- PostUpdateIdentifier.create(postMetadataProto.postUpdateIdentifier),
            postCreatorUserIdEither <- postMetadataProto.postCreatorID.toUUID(),
            yield: PostMetadata(
                PostUpdateIdentifier: PostUpdateIdentifierEither.get,
                postType: postMetadataProto.postType,
                postState: postMetadataProto.postState,
                createdAt: postMetadataProto.createdAt.date,
                postCreatorUserId: postCreatorUserIdEither.get
            )
        )^
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let postTypeRawValue = try values.decode(Int.self, forKey: .postType)
        let postStateRawValue = try values.decode(Int.self, forKey: .postState)

        self.init(
            PostUpdateIdentifier: try PostUpdateIdentifier(from: decoder),
            postType: Post.PostType(rawValue: postTypeRawValue) ?? Post.PostType.UNRECOGNIZED(postTypeRawValue),
            postState: Post.PostState(rawValue: postStateRawValue) ?? Post.PostState.UNRECOGNIZED(postStateRawValue),
            createdAt: try values.decode(Date.self, forKey: .createdAt),
            postCreatorUserId: try UUID(uuidString: values.decode(String.self, forKey: .postCreatorUserId)).getOrThrow()
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try postUpdateIdentifier.encode(to: encoder)
        try container.encode(postType.rawValue, forKey: .postType)
        try container.encode(postState.rawValue, forKey: .postState)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(postCreatorUserId, forKey: .postCreatorUserId)
    }
}

public extension Post.PostMetadata {
    func toPostMetadata() -> Either<PulpFictionRequestError, PostMetadata> {
        PostMetadata.create(self)
    }
}
