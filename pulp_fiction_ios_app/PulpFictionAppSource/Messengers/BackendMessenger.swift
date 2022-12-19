//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import Bow
import ComposableArchitecture
import Foundation
import Logging
import protos_pulp_fiction_grpc_swift

/// Struct for communicating with backend API
public struct BackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession
    private let logger = Logger(label: String(describing: BackendMessenger.self))

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol, loginSession: LoginSession) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.loginSession = loginSession
    }

    class ErrorLikingPost: PulpFictionRequestError {}

    private func buildUpdatePostResponse(updatePostRequest: UpdatePostRequest) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        Either<PulpFictionRequestError, UpdatePostResponse>.invoke({ cause in ErrorLikingPost(cause) }) {
            try pulpFictionClientProtocol.updatePost(updatePostRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called updatePost" }
        .logError("Error calling updatePost")
    }

    func updatePostLikeStatus(postId: UUID, newPostLikeStatus: Post.PostLike) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        let updatePostRequest = UpdatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.postID = postId.uuidString
            $0.updatePostLikeStatus = UpdatePostRequest.UpdatePostLikeStatus.with {
                $0.newPostLikeStatus = newPostLikeStatus
            }
        }

        return await buildUpdatePostResponse(updatePostRequest: updatePostRequest)
    }

    func deletePost(postId: UUID) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        let updatePostRequest = UpdatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.postID = postId.uuidString
            $0.deletePost = UpdatePostRequest.DeletePost()
        }

        return await buildUpdatePostResponse(updatePostRequest: updatePostRequest)
    }

    func reportPost(postId: UUID, reportReason: String) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        let updatePostRequest = UpdatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.postID = postId.uuidString
            $0.reportPost = UpdatePostRequest.ReportPost.with {
                $0.reportReason = reportReason
            }
        }

        return await buildUpdatePostResponse(updatePostRequest: updatePostRequest)
    }
}

extension Either<PulpFictionRequestError, UpdatePostResponse> {
    func processResponseFromServer(
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        state: Any,
        successAction: @escaping () -> Void = {},
        failureAction: @escaping () -> Void = {}
    ) {
        switch toEnum() {
        case let .left(pulpFictionRequestError):
            pulpFictionRequestError.processErrorResponseFromServer(
                notificationBannerViewStore: notificationBannerViewStore,
                action: failureAction
            )
        case let .right(updatePostResponse):
            updatePostResponse.processSuccessResponseFromServer(
                state: state,
                action: successAction
            )
        }
    }
}

extension UpdatePostResponse {
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
        action: () -> Void = {}
    ) {
        logger.error("Error communicating with server",
                     metadata: [
                         "error": "\(self)",
                         "cause": "\(String(describing: causeMaybe.orNil))",
                     ])

        action()
        notificationBannerViewStore.send(.showNotificationBanner("Error contacting server. Please try again later.", .error))
    }
}
