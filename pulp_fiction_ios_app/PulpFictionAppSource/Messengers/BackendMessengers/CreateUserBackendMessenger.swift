//
//  CreateUserBackendMessenger.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 12/31/22.
//

import Bow
import Foundation
import SwiftUI

public struct CreateUserBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorCreatingUser: PulpFictionRequestError {}

    private func buildCreateUserResponse(createUserRequest: CreateUserRequest) async -> Either<PulpFictionRequestError, CreateUserResponse> {
        .invoke({ cause in ErrorCreatingUser(cause) }) {
            try pulpFictionClientProtocol.createUser(createUserRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called createUser" }
        .logError("Error calling createUser")
    }

    private func buildCreateUserRequest(
        password: String,
        passwordConfirmation: String,
        setContactVerification: (inout CreateUserRequest) -> Void
    ) -> CreateUserRequest {
        CreateUserRequest.with { createUserRequest in
            createUserRequest.password = password
            createUserRequest.passwordConfirmation = passwordConfirmation
            setContactVerification(&createUserRequest)
        }
    }

    func createUser(phoneNumber: String, password: String, passwordConfirmation: String) async -> Either<PulpFictionRequestError, CreateUserResponse> {
        let createUserRequest = buildCreateUserRequest(
            password: password,
            passwordConfirmation: passwordConfirmation
        ) {
            $0.phoneNumberVerification = CreateUserRequest.PhoneNumberVerification.with {
                $0.phoneNumber = phoneNumber
            }
        }

        return await buildCreateUserResponse(createUserRequest: createUserRequest)
    }

    func createUser(email: String, password: String, passwordConfirmation: String) async -> Either<PulpFictionRequestError, CreateUserResponse> {
        let createUserRequest = buildCreateUserRequest(
            password: password,
            passwordConfirmation: passwordConfirmation
        ) {
            $0.emailVerification = CreateUserRequest.EmailVerification.with {
                $0.email = email
            }
        }

        return await buildCreateUserResponse(createUserRequest: createUserRequest)
    }
}
