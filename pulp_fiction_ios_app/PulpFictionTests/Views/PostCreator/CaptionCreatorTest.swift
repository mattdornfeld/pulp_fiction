//
//  CaptionCreatorTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/21/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class CaptionCreatorTest: XCTestCase {
    func buildCaptionCreator() throws -> CaptionCreator {
        let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
        let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
        let uiImageEither = Either<PulpFictionRequestError, UIImage>.var()
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            userPostDataEither <- UserPostData
                .generate()
                .unsafeRunSyncEither(),
            imagePostDataEither <- ImagePostData
                .generate()
                .unsafeRunSyncEither(),
            uiImageEither <- imagePostDataEither
                .get
                .imagePostContentData
                .toUIImage(),
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: CaptionCreator(
                loggedInUserPostData: userPostDataEither.get,
                externalMessengers: externalMessengersEither.get,
                notificationBannerViewStore: NotificationBanner.buildViewStore(),
                uiImageMaybeSupplier: { uiImageEither.get }
            )
        )^.getOrThrow()
    }

    func test() async throws {
        let captionCreator = try buildCaptionCreator()
        let store = TestStore(
            initialState: EditTextReducer.State(),
            reducer: captionCreator.editTextView.reducer
        )

        let expectedCaption = "expectedCaption"
        await store.send(.updateText(expectedCaption)) {
            $0.text = expectedCaption
        }
        await store.send(.submitText)
        await store.receive(.processSuccessfulButtonPush)

        let pulpFictionTestClientWithFakeData = captionCreator.backendMessenger.getPulpFictionTestClientWithFakeData()
        let createPostRequest = pulpFictionTestClientWithFakeData.requestBuffers.createPost[0]
        XCTAssertEqual(
            captionCreator.backendMessenger.loginSession.toProto(),
            createPostRequest.loginSession
        )
        XCTAssertEqual(
            try captionCreator.uiImageMaybeSupplier()?.serializeImage().getOrThrow(),
            createPostRequest.createImagePostRequest.imageJpg
        )
        XCTAssertEqual(
            expectedCaption,
            createPostRequest.createImagePostRequest.caption
        )
    }
}
