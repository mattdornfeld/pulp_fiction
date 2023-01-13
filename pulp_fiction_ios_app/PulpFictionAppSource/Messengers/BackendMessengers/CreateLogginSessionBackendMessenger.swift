//
//  CreateLogginSessionBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import Bow
import Foundation
import SwiftUI

public struct CreateLogginSessionBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorCreatingLoginSession: PulpFictionRequestError {}

    enum BackendPath: String {
        case createLoginSession
    }

    private func buildCreateLoginSessionResponse(createLoginSessionRequest: CreateLoginSessionRequest) async -> PulpFictionRequestEither<CreateLoginSessionResponse> {
        .invoke({ cause in ErrorCreatingLoginSession(cause) }) {
            try pulpFictionClientProtocol.createLoginSession(createLoginSessionRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called createLoginSession" }
        .logError("Error calling createLoginSession")
    }

    func getDeviceId() -> String {
        UIDevice
            .current
            .identifierForVendor
            .map { $0.uuidString }
            .getOrElse("")
    }

    func createLoginSession(email: String, password: String) async -> PulpFictionRequestEither<CreateLoginSessionResponse> {
        let createLoginSessionRequest = CreateLoginSessionRequest.with {
            $0.password = password
            $0.deviceID = getDeviceId()
            $0.emailLogin = CreateLoginSessionRequest.EmailLogin.with {
                $0.email = email
            }
        }

        return await buildCreateLoginSessionResponse(createLoginSessionRequest: createLoginSessionRequest)
    }

    func createLoginSession(phoneNumber: String, password: String) async -> PulpFictionRequestEither<CreateLoginSessionResponse> {
        let createLoginSessionRequest = CreateLoginSessionRequest.with {
            $0.password = password
            $0.deviceID = getDeviceId()
            $0.phoneNumberLogin = CreateLoginSessionRequest.PhoneNumberLogin.with {
                $0.phoneNumber = phoneNumber
            }
        }

        return await buildCreateLoginSessionResponse(createLoginSessionRequest: createLoginSessionRequest)
    }
}
