//
//  DeletePostMenuTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/18/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class DeletePostMenuTest: XCTestCase {
    private let expectedUpdatePostResponseEither: Either<PulpFictionRequestError, UpdatePostResponse> = .right(UpdatePostResponse())

    private var reducerEither: Either<PulpFictionRequestError, DeletePostMenuReducer<ImagePostView>> {
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
            yield: {
                let postViewEitherSupplier = ImagePostView
                    .getPostViewEitherSupplier(
                        externalMessengers: externalMessengersEither.get,
                        notificationBannerViewStore: NotificationBanner.buildViewStore()
                    )
                let contentScrollViewStore = ContentScrollView<ImagePostView, EmptyView>
                    .buildViewStore(postViewEitherSupplier: postViewEitherSupplier)

                let extraOptionsDropDownMenuViewStore = ExtraOptionsDropDownMenuView<ImagePostView>.buildViewStore()

                return DeletePostMenuReducer(
                    postMetadata: imagePostDataEither.get.postMetadata,
                    backendMessenger: externalMessengersEither.get.backendMessenger,
                    extraOptionsDropDownMenuViewStore: extraOptionsDropDownMenuViewStore,
                    notificationBannerViewStore: NotificationBanner.buildViewStore(),
                    contentScrollViewStore: contentScrollViewStore
                )
            }()
        )^
    }

    private func buildTestStore(reducer: DeletePostMenuReducer<ImagePostView>) -> PulpFictionTestStore<DeletePostMenuReducer<ImagePostView>> {
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
        let updatePostRequest = pulpFictionClientProtocol.requestBuffers.updatePost[0]
        XCTAssertEqual(reducer.postMetadata.postUpdateIdentifier.postId.uuidString, updatePostRequest.postID)
        XCTAssertEqual(reducer.backendMessenger.loginSession.toProto(), updatePostRequest.loginSession)
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
