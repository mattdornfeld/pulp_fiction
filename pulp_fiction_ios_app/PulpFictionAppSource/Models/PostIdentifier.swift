//
//  PostUpdateIdentifier.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/26/22.
//

import Bow
import Foundation

/// Uniquely identifies a post as the union type of its postId and its version represented as the time it was createdAt
public struct PostUpdateIdentifier: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let postId: UUID
    public let updatedAt: Date

    public init(postId: UUID, updatedAt: Date) {
        self.id = PostUpdateIdentifier.getUniqueId(postId, updatedAt)
        self.postId = postId
        self.updatedAt = updatedAt
    }

    private static func getUniqueId(_ postId: UUID, _ updatedAt: Date) -> String {
        postId.uuidString + String(updatedAt.timeIntervalSince1970)
    }

    static func create(_ postUpdateIdentifierProto: Post.PostUpdateIdentifier) -> Either<PulpFictionRequestError, PostUpdateIdentifier> {
        return postUpdateIdentifierProto.postID.toUUID().mapRight { postId in
            PostUpdateIdentifier(
                postId: postId,
                updatedAt: postUpdateIdentifierProto.updatedAt.date
            )
        }
    }
}

/// All post data models with a unique identity implement this protocol. The id field is always PostUpdateIdentifier.
public protocol PostDataIdentifiable: Identifiable {
    var id: PostUpdateIdentifier { get }
}
