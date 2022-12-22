//
//  UpdateUserBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import Bow
import Foundation
import SwiftUI

public struct UpdateUserBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorUpdatingUser: PulpFictionRequestError {}

    enum BackendPath: String {
        case updateUserFollowingStatus
        case updateUserAvatarUIImage
        case updateDisplayName
    }

    private func buildUpdateUserResponse(updateUserRequest: UpdateUserRequest) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        Either<PulpFictionRequestError, UpdateUserResponse>.invoke({ cause in ErrorUpdatingUser(cause) }) {
            try pulpFictionClientProtocol.updateUser(updateUserRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called updateUser" }
        .logError("Error calling updateUser")
    }

    private func buildUpdateUserResponse(updateUserRequestEither: Either<PulpFictionRequestError, UpdateUserRequest>) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        switch updateUserRequestEither.toEnum() {
        case let .left(pulpFictionRequestError):
            return .left(pulpFictionRequestError)
        case let .right(updateUserRequest):
            return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
        }
    }

    func updateUserFollowingStatus(targetUserId: UUID, newUserFollowingStatus: UpdateUserRequest.UpdateUserFollowingStatus.UserFollowingStatus) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateUserFollowingStatus = UpdateUserRequest.UpdateUserFollowingStatus.with {
                $0.targetUserID = targetUserId.uuidString
                $0.userFollowingStatus = newUserFollowingStatus
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func updateUserAvatarUIImage(avatarUIImage: UIImage) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let avatarJpgEither = Either<PulpFictionRequestError, Data>.var()
        let updateUserRequestEither = binding(
            avatarJpgEither <- avatarUIImage.serializeImage(),
            yield: UpdateUserRequest.with {
                $0.loginSession = loginSession.toProto()
                $0.updateUserAvatar = UpdateUserRequest.UpdateUserAvatar.with {
                    $0.avatarJpg = avatarJpgEither.get
                }
            }
        )^

        return await buildUpdateUserResponse(updateUserRequestEither: updateUserRequestEither)
    }

    func updateDisplayName(newDisplayName: String) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateDisplayName = UpdateUserRequest.UpdateDisplayName.with {
                $0.newDisplayName = newDisplayName
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }
}
