//
//  LoginSession.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/21/22.
//

import Foundation

public class LoginSession {
    let loggedInUserPostData: UserPostData

    public init(loggedInUserPostData: UserPostData) {
        self.loggedInUserPostData = loggedInUserPostData
    }

    func toProto() -> CreateLoginSessionResponse.LoginSession {
        CreateLoginSessionResponse.LoginSession.with { _ in }
    }
}
