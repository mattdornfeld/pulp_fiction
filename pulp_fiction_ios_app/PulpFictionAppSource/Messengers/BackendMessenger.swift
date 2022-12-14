//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import BowEffects
import Foundation
import protos_pulp_fiction_grpc_swift

/// Struct for communicating with backend API
public struct BackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    public init(pulpFictionClientProtocol: PulpFictionClientProtocol, loginSession: LoginSession) {
        self.pulpFictionClientProtocol = pulpFictionClientProtocol
        self.loginSession = loginSession
    }

    class ErrorLikingPost: PulpFictionRequestError {}

    private func buildUpdatePostResponse(updatePostRequest: UpdatePostRequest) -> IO<PulpFictionRequestError, UpdatePostResponse> {
        IO<PulpFictionRequestError, UpdatePostResponse>.invokeAndConvertError({ cause in ErrorLikingPost(cause) }) {
            try pulpFictionClientProtocol.updatePost(updatePostRequest).response.wait()
        }
    }

    func updatePostLikeStatus(postId: UUID, newPostLikeStatus: Post.PostLike) -> IO<PulpFictionRequestError, UpdatePostResponse> {
        let updatePostRequest = UpdatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.postID = postId.uuidString
            $0.updatePostLikeStatus = UpdatePostRequest.UpdatePostLikeStatus.with {
                $0.newPostLikeStatus = newPostLikeStatus
            }
        }

        return buildUpdatePostResponse(updatePostRequest: updatePostRequest)
    }
}
