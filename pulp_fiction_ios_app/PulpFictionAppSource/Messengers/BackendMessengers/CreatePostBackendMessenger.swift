//
//  CreatePostBackendMessenger.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/21/22.
//

import Bow
import Foundation
import SwiftUI

public struct CreatePostBackendMessenger {
    public let pulpFictionClientProtocol: PulpFictionClientProtocol
    public let loginSession: LoginSession

    class NoImageSelected: PulpFictionRequestError {}
    class ErrorCreatingPost: PulpFictionRequestError {}

    private func buildCreatePostResponse(createPostRequest: CreatePostRequest) async -> Either<PulpFictionRequestError, CreatePostResponse> {
        Either<PulpFictionRequestError, CreatePostResponse>.invoke({ cause in ErrorCreatingPost(cause) }) {
            try pulpFictionClientProtocol.createPost(createPostRequest).response.wait()
        }
        .logSuccess(level: .debug) { _ in "Successfuly called createPost" }
        .logError("Error calling createPost")
    }

    func createComment(parentPostId: UUID, commentBody: String) async -> Either<PulpFictionRequestError, CreatePostResponse> {
        let createPostRequest = CreatePostRequest.with {
            $0.loginSession = loginSession.toProto()
            $0.createCommentRequest = CreatePostRequest.CreateCommentRequest.with {
                $0.parentPostID = parentPostId.uuidString
                $0.body = commentBody
            }
        }

        return await buildCreatePostResponse(createPostRequest: createPostRequest)
    }

    func createImagePost(uiImageMaybe: UIImage?, caption: String) async -> Either<PulpFictionRequestError, CreatePostResponse> {
        let uiImageEither = Either<PulpFictionRequestError, UIImage>.var()
        let uiImageDataEither = Either<PulpFictionRequestError, Data>.var()

        let createPostRequestEither = binding(
            uiImageEither <- uiImageMaybe
                .toEither(NoImageSelected())
                .logError("Cannot create ImagePost. No image selected."),
            uiImageDataEither <- uiImageEither
                .get
                .serializeImage(),
            yield: CreatePostRequest.with {
                $0.loginSession = loginSession.toProto()
                $0.createImagePostRequest = CreatePostRequest.CreateImagePostRequest.with {
                    $0.caption = caption
                    $0.imageJpg = uiImageDataEither.get
                }
            }
        )^

        switch createPostRequestEither.toEnum() {
        case let .left(pulpFictionRequestError):
            return Either.left(pulpFictionRequestError)
        case let .right(createPostRequest):
            return await buildCreatePostResponse(createPostRequest: createPostRequest)
        }
    }
}
