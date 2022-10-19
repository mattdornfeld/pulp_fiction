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
    public let postFeedMessenger: PostFeedMessenger

    public init(
        backendMessenger: BackendMessenger,
        postDataMessenger: PostDataMessenger,
        postFeedMessenger: PostFeedMessenger
    ) {
        self.backendMessenger = backendMessenger
        self.postDataMessenger = postDataMessenger
        self.postFeedMessenger = postFeedMessenger
    }
}
