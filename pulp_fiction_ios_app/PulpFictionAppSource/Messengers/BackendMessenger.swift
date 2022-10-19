//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import Foundation
import protos_pulp_fiction_grpc_swift

/// Struct for communicating with backend API
public struct BackendMessenger {
    private let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let loginSession = LoginSession.with { _ in }

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
    }
}
