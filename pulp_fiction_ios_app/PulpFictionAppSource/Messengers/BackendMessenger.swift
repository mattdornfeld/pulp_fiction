//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import Foundation
import protos_pulp_fiction_grpc_swift

public struct BackendMessenger {
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    private let loginSession = LoginSession.with { _ in }

    func getGlobalPostFeed() -> PostFeedBuilder.PostFeed {
        let getFeedRequest = GetFeedRequest.with {
            $0.loginSession = loginSession
            $0.getGlobalFeedRequest = GetFeedRequest.GetGlobalFeedRequest()
        }

        return PostFeedBuilder(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            getFeedRequest: getFeedRequest
        ).makeAsyncIterator()
    }
}
