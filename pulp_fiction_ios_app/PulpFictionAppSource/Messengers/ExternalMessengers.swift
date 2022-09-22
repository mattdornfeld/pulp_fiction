//
//  ExternalMessengers.swift
//
//  Created by Matthew Dornfeld on 9/18/22.
//
//

import Foundation

public struct ExternalMessengers {
    public let backendMessenger: BackendMessenger
    public let postDataMessenger: PostDataMessenger
}

public extension ExternalMessengers {
    init(
        pulpFictionClientProtocol: PulpFictionClientProtocol,
        postDataCache: PostDataCache
    ) {
        let backendMessenger = BackendMessenger(pulpFictionClientProtocol: pulpFictionClientProtocol)
        let postDataMessenger = PostDataMessenger(postDataCache: postDataCache)

        self.init(
            backendMessenger: backendMessenger,
            postDataMessenger: postDataMessenger
        )
    }
}
