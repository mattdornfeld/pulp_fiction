//
//  DeletePostMenuTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/18/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class DeletePostMenuTest: XCTestCase {
    private let expectedUpdatePostResponseEither: Either<PulpFictionRequestError, UpdatePostResponse> = .right(UpdatePostResponse())

    var reducerEither: Either<PulpFictionRequestError, DeletePostMenuReducer> {
        let imagePostDataEither = Either<PulpFictionRequestError, ImagePostData>.var()
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return binding(
            imagePostDataEither <- ImagePostData
                .generate()
                .unsafeRunSyncEither(),
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: DeletePostMenuReducer(
                postMetadata: imagePostDataEither.get.postMetadata,
                backendMessenger: externalMessengersEither.get.backendMessenger,
                extraOptionsDropDownMenuViewStore: ExtraOptionsDropDownMenuView.buildViewStore(),
                notificationBannerViewStore: NotificationBanner.buildViewStore()
            )
        )^
    }

    func buildTestStore(reducer: DeletePostMenuReducer) -> PulpFictionTestStore<DeletePostMenuReducer> {
        TestStore(
            initialState: DeletePostMenuReducer.State(),
            reducer: reducer
        )
    }

    func testDeletingPost() async throws {
        let reducer = try reducerEither.getOrThrow()
        let store = buildTestStore(reducer: reducer)
        await store.send(.deletePost)
        await store.receive(.processUpdatePostResponse(expectedUpdatePostResponseEither))

        let pulpFictionClientProtocol = reducer.backendMessenger.pulpFictionClientProtocol as! PulpFictionTestClientWithFakeData
        let updatePostRequest = pulpFictionClientProtocol.updatePostRequests[0]
        XCTAssertEqual(reducer.postMetadata.postUpdateIdentifier.postId.uuidString, updatePostRequest.postID)
        let isDeletePostRequest = {
            switch updatePostRequest.updatePostRequest {
            case .deletePost:
                return true
            default:
                return false
            }
        }()
        XCTAssertTrue(isDeletePostRequest)
    }
}
