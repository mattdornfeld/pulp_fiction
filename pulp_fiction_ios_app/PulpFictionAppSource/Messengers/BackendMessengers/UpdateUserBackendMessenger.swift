//
//  UpdateUserBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import Bow
import Foundation

public struct UpdateUserBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorUpdatingUser: PulpFictionRequestError {}

    private func buildUpdateUserResponse(updateUserRequest: UpdateUserRequest) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        Either<PulpFictionRequestError, UpdateUserResponse>.invoke({ cause in ErrorUpdatingUser(cause) }) {
            try pulpFictionClientProtocol.updateUser(updateUserRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called updatePost" }
        .logError("Error calling updatePost")
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
}
