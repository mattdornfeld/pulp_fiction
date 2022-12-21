//
//  CommentCreatorTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/19/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class CommentCreatorTest: XCTestCase {
    func buildCommentCreator() throws -> CommentCreator {
        let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            imagePostDataEither <- ImagePostData
                .generate()
                .unsafeRunSyncEither(),
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: CommentCreator(
                postMetadata: imagePostDataEither.get.postMetadata,
                backendMessenger: externalMessengersEither.get.backendMessenger,
                notificationnotificationBannerViewStore: NotificationBanner.buildViewStore()
            )
        )^.getOrThrow()
    }

    func testCommentOnPost() async throws {
        let commentCreator = try buildCommentCreator()
        let store = TestStore(
            initialState: EditTextReducer.State(),
            reducer: commentCreator.editTextView.reducer
        )

        let expectedComment = "expectedComment"
        await store.send(.updateText(expectedComment)) {
            $0.text = expectedComment
        }
        await store.send(.submitText)
        await store.receive(.processSuccessfulButtonPush)

        let pulpFictionTestClientWithFakeData = commentCreator.backendMessenger.getPulpFictionTestClientWithFakeData()
        let updatePostRequest = pulpFictionTestClientWithFakeData.requestBuffers.updatePost[0]
        XCTAssertEqual(commentCreator.postMetadata.postId.uuidString, updatePostRequest.postID)
        XCTAssertEqual(commentCreator.backendMessenger.loginSession.toProto(), updatePostRequest.loginSession)
        XCTAssertEqual(expectedComment, updatePostRequest.commentOnPost.body)
    }
}
