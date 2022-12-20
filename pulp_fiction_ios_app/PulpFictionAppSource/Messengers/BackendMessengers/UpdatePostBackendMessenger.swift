//
//  UpdatePostBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import Bow
import ComposableArchitecture
import Foundation
import protos_pulp_fiction_grpc_swift

public struct UpdatePostBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class ErrorUpdatingPost: PulpFictionRequestError {}

    private func buildUpdatePostResponse(updatePostRequest: UpdatePostRequest) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        Either<PulpFictionRequestError, UpdatePostResponse>.invoke({ cause in ErrorUpdatingPost(cause) }) {
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

    func commentOnPost(postId: UUID, commentBody: String) async -> Either<PulpFictionRequestError, UpdatePostResponse> {
        let updatePostRequest = UpdatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.postID = postId.uuidString
            $0.commentOnPost = UpdatePostRequest.CommentOnPost.with {
                $0.body = commentBody
            }
        }

        return await buildUpdatePostResponse(updatePostRequest: updatePostRequest)
    }
}
