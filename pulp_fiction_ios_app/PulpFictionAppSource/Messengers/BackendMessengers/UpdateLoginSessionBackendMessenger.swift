//
//  UpdateLoginSessionBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/25/22.
//

import Bow
import Foundation
import SwiftUI

public struct UpdateLogginSessionBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorUpdatingLoginSession: PulpFictionRequestError {}

    enum BackendPath: String {
        case logout
    }

    private func buildCreateLoginSessionResponse(updateLoginSessionRequest: UpdateLoginSessionRequest) async -> PulpFictionRequestEither<UpdateLoginSessionResponse> {
        .invoke({ ErrorUpdatingLoginSession($0) }) {
            try pulpFictionClientProtocol.updateLoginSession(updateLoginSessionRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called updateLoginSession" }
        .logError("Error calling updateLoginSession")
    }

    func logout() async -> PulpFictionRequestEither<UpdateLoginSessionResponse> {
        let updateLoginSessionRequest = UpdateLoginSessionRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.logout = UpdateLoginSessionRequest.Logout()
        }

        return await buildCreateLoginSessionResponse(updateLoginSessionRequest: updateLoginSessionRequest)
    }
}
