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
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let loginSession = LoginSession.with { _ in }

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
    }

    /// Constructs the global post feed based on data returned from backend API
    /// - Returns: A PostFeed iterator that returns PostProto objects for the global feed
    func getGlobalPostFeed() -> PostFeed {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession
            $0.getGlobalFeedRequest = GetFeedRequest.GetGlobalFeedRequest()
        }

        return PostFeed(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest
        )
    }
}
