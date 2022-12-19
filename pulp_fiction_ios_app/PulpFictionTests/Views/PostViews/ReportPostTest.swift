//
//  ReportPostViewTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/19/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class ReportPostTest: XCTestCase {
    private let expectedUpdatePostResponseEither: Either<PulpFictionRequestError, UpdatePostResponse> = .right(UpdatePostResponse())

    private var reducerEither: Either<PulpFictionRequestError, ReportPostReducer> {
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
            yield: ReportPostReducer(
                postMetadata: imagePostDataEither.get.postMetadata,
                backendMessenger: externalMessengersEither.get.backendMessenger,
                notificationBannerViewStore: NotificationBanner.buildViewStore()
            )
        )^
    }

    private func buildTestStore(reducer: ReportPostReducer) -> PulpFictionTestStore<ReportPostReducer> {
        TestStore(
            initialState: ReportPostReducer.State(),
            reducer: reducer
        )
    }

    func testReportPost() async throws {
        let reducer = try reducerEither.getOrThrow()
        let store = buildTestStore(reducer: reducer)
        let expectedReportReason = "expectedReportReason"

        await store.send(.updateReportReason(expectedReportReason)) {
            $0.reportReason = expectedReportReason
        }
        await store.send(.reportPost(EquatableClosure0 {}))
        await store.receive(.processUpdatePostResponse(expectedUpdatePostResponseEither, EquatableClosure0 {}))

        let pulpFictionClientProtocol = reducer.backendMessenger.pulpFictionClientProtocol as! PulpFictionTestClientWithFakeData
        let updatePostRequest = pulpFictionClientProtocol.updatePostRequests[0]
        XCTAssertEqual(reducer.postMetadata.postUpdateIdentifier.postId.uuidString, updatePostRequest.postID)
        XCTAssertEqual(reducer.backendMessenger.loginSession.toProto(), updatePostRequest.loginSession)
        XCTAssertEqual(expectedReportReason, updatePostRequest.reportPost.reportReason)
    }
}
