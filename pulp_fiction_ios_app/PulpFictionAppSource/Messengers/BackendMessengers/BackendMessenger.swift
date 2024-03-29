//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import Bow
import Foundation
import Logging
import protos_pulp_fiction_grpc_swift
import SwiftProtobuf

/// Struct for communicating with backend API
public struct BackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession
    public let createLoginSessionBackendMessenger: CreateLogginSessionBackendMessenger
    public let createPostBackendMessenger: CreatePostBackendMessenger
    public let createUserBackendMessenger: CreateUserBackendMessenger
    public let updateLoginSessionBackendMessenger: UpdateLogginSessionBackendMessenger
    public let updatePostBackendMessenger: UpdatePostBackendMessenger
    public let updateUserBackendMessenger: UpdateUserBackendMessenger

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol, loginSession: LoginSession) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.loginSession = loginSession
        updatePostBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
        updateUserBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
        createPostBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
        createLoginSessionBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
        updateLoginSessionBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
        createUserBackendMessenger = .init(
            pulpFictionClientProtocol: pulpFictionClientProtocol,
            loginSession: loginSession
        )
    }
}

typealias BackendPath = String

extension Either where A: PulpFictionRequestError, B: SwiftProtobuf.Message {
    @discardableResult
    func processResponseFromServer(
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        state: Any,
        path: BackendPath,
        successAction: @escaping () -> Void = {},
        failureAction: @escaping () -> Void = {}
    ) -> Either<A, B> {
        switch toEnum() {
        case let .left(pulpFictionRequestError):
            pulpFictionRequestError.processErrorResponseFromServer(
                notificationBannerViewStore: notificationBannerViewStore,
                path: path,
                action: failureAction
            )
        case let .right(updatePostResponse):
            updatePostResponse.processSuccessResponseFromServer(
                state: state,
                action: successAction
            )
        }
        return self
    }
}

extension SwiftProtobuf.Message {
    private var logger: Logger { Logger(label: String(describing: UpdatePostResponse.self)) }

    func processSuccessResponseFromServer(
        state: Any,
        action: () -> Void = {}
    ) {
        logger.debug(
            "Successfully processed response from server",
            metadata: [
                "updatePostResponse": "\(String(describing: self))",
                "state": "\(String(describing: state))",
            ]
        )
        action()
    }
}

extension PulpFictionRequestError {
    private var logger: Logger { Logger(label: String(describing: PulpFictionRequestError.self)) }

    func processErrorResponseFromServer(
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        path: String,
        action: () -> Void = {}
    ) {
        logger.error("Error communicating with server",
                     metadata: [
                         "error": "\(self)",
                         "cause": "\(String(describing: causeMaybe.orNil))",
                         "path": "\(path)",
                     ])

        action()
        notificationBannerViewStore.send(.showNotificationBanner("Error contacting server. Please try again later.", .error))
    }
}
