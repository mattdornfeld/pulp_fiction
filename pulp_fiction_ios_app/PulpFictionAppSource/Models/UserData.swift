//
//  UserData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/16/22.
//
import Bow
import Foundation

public struct UserMetadata: Codable, Equatable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let displayName: String
    public let avatarImageUrl: String
    public let createdAt: Date
    public let avatarImageJpg: Data

    static func create(_ userMetadataProto: UserMetadataProto, _ avatarImageJpg: Data) -> Either<PulpFictionRequestError, UserMetadata> {
        userMetadataProto.userID.toUUID().mapRight { userId in
            UserMetadata(
                id: userId,
                userId: userId,
                displayName: userMetadataProto.displayName,
                avatarImageUrl: userMetadataProto.avatarImageURL,
                createdAt: userMetadataProto.createdAt.date,
                avatarImageJpg: avatarImageJpg
            )
        }
    }
}
