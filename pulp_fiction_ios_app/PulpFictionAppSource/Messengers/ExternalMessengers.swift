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

    public init(backendMessenger: BackendMessenger, postDataMessenger: PostDataMessenger) {
        self.backendMessenger = backendMessenger
        self.postDataMessenger = postDataMessenger
    }
}
