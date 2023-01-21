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
        case updateBio
        case updateEmail
        case updatePhoneNumber
        case updateDateOfBirth
        case verifyContactInformation
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
                $0.updateUserMetadata = UpdateUserRequest.UpdateUserMetadata.with {
                    $0.updateUserAvatar = UpdateUserRequest.UpdateUserMetadata.UpdateUserAvatar.with {
                        $0.avatarJpg = avatarJpgEither.get
                    }
                }
            }
        )^

        return await buildUpdateUserResponse(updateUserRequestEither: updateUserRequestEither)
    }

    func updateDisplayName(newDisplayName: String) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateUserMetadata = UpdateUserRequest.UpdateUserMetadata.with {
                $0.updateDisplayName = UpdateUserRequest.UpdateUserMetadata.UpdateDisplayName.with {
                    $0.newDisplayName = newDisplayName
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func updateBio(newBio: String) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateUserMetadata = UpdateUserRequest.UpdateUserMetadata.with {
                $0.updateBio = UpdateUserRequest.UpdateUserMetadata.UpdateBio.with {
                    $0.newBio = newBio
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func updateEmail(newEmail: String) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateSensitiveUserMetadata = UpdateUserRequest.UpdateSensitiveUserMetadata.with {
                $0.updateEmail = UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateEmail.with {
                    $0.newEmail = newEmail
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func updatePhoneNumber(newPhoneNumber: String) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateSensitiveUserMetadata = UpdateUserRequest.UpdateSensitiveUserMetadata.with {
                $0.updatePhoneNumber = UpdateUserRequest.UpdateSensitiveUserMetadata.UpdatePhoneNumber.with {
                    $0.newPhoneNumber = newPhoneNumber
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func updateDateOfBirth(newDateOfBirth: Date) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateSensitiveUserMetadata = UpdateUserRequest.UpdateSensitiveUserMetadata.with {
                $0.updateDateOfBirth = UpdateUserRequest.UpdateSensitiveUserMetadata.UpdateDateOfBirth.with {
                    $0.newDateOfBirth = .init(date: newDateOfBirth)
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }

    func verifyContactInformation(verificationCode: Int32, contactVerificationProto: ContactVerificationProto) async -> Either<PulpFictionRequestError, UpdateUserResponse> {
        let updateUserRequest = UpdateUserRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.updateSensitiveUserMetadata = UpdateUserRequest.UpdateSensitiveUserMetadata.with {
                $0.verifyContactInformation = UpdateUserRequest.UpdateSensitiveUserMetadata.VerifyContactInformation.with {
                    $0.verificationCode = verificationCode
                    $0.contactVerification = contactVerificationProto
                }
            }
        }

        return await buildUpdateUserResponse(updateUserRequest: updateUserRequest)
    }
}
