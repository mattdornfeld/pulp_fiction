//
//  PostLikeOnSwipeViewTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/14/22.
//

import Bow
import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

@MainActor
class PostLikeOnSwipeViewTest: XCTestCase {
    private let expectedUpdatePostResponse: Either<PulpFictionRequestError, UpdatePostResponse> = .right(UpdatePostResponse())
    var reducerEither: Either<PulpFictionRequestError, PostLikeArrowReducer> {
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
            yield: PostLikeArrowReducer(
                backendMessenger: externalMessengersEither.get.backendMessenger,
                postMetadata: imagePostDataEither.get.postMetadata
            )
        )^
    }

    private func getTestStore(
        reducer: PostLikeArrowReducer,
        loggedInUserPostLikeStatus: Post.PostLike
    ) throws -> TestStore<PostLikeArrowReducer.State, PostLikeArrowReducer.Action, PostLikeArrowReducer.State, PostLikeArrowReducer.Action, Void> {
        return TestStore(
            initialState: PostLikeArrowReducer.State(
                loggedInUserPostLikeStatus: loggedInUserPostLikeStatus,
                postNumNetLikes: 0
            ),
            reducer: reducer
        )
    }

    func testShowErrorAlert() async throws {
        try await getTestStore(
            reducer: reducerEither.getOrThrow(),
            loggedInUserPostLikeStatus: .like
        )
        .send(.updateShowErrorCommunicatingWithServerAlert(true)) {
            $0.showErrorCommunicatingWithServerAlert = true
        }
    }

    func testUpdatePostLikeStatus() async throws {
        let testData: [(Post.PostLike, PostLikeOnSwipeReducer.Action, Post.PostLike, Int64)] = [
            (.neutral, .swipeLeft, .like, 1),
            (.neutral, .swipeRight, .dislike, -1),
            (.like, .swipeLeft, .neutral, -1),
            (.dislike, .swipeRight, .neutral, 1),
            (.dislike, .swipeLeft, .like, 1),
            (.like, .swipeRight, .dislike, -2),
        ]

        try await testData.asyncForEach { initialPostLikeStatus, postSwipeAction, expectedPostLikeStatus, expectedPostNumNetLikes in
            let reducer = try reducerEither.getOrThrow()

            let store = try getTestStore(
                reducer: reducer,
                loggedInUserPostLikeStatus: initialPostLikeStatus
            )

            await store.send(.updatePostLikeStatus(postSwipeAction))

            await store.receive(
                .processUpdatePostLikeStatusResponseFromBackend((expectedPostLikeStatus, expectedPostNumNetLikes), expectedUpdatePostResponse)
            ) {
                $0.loggedInUserPostLikeStatus = expectedPostLikeStatus
                $0.postNumNetLikes = expectedPostNumNetLikes
            }

            let pulpFictionClientProtocol = reducer.backendMessenger.pulpFictionClientProtocol as! PulpFictionTestClientWithFakeData
            let updatePostResponse = pulpFictionClientProtocol.updatePostRequests[0]
            XCTAssertEqual(reducer.postMetadata.postUpdateIdentifier.postId.uuidString, updatePostResponse.postID)
            XCTAssertEqual(expectedPostLikeStatus, updatePostResponse.updatePostLikeStatus.newPostLikeStatus)
        }
    }

    func testTapPostLikeArrow() async throws {
        let store = try getTestStore(
            reducer: try reducerEither.getOrThrow(),
            loggedInUserPostLikeStatus: .neutral
        )

        await store.send(.tapPostLikeArrow)
        await store.receive(.updatePostLikeStatus(.swipeLeft))
        await store
            .receive(.processUpdatePostLikeStatusResponseFromBackend((.like, 1), expectedUpdatePostResponse)) {
                $0.loggedInUserPostLikeStatus = .like
                $0.postNumNetLikes = 1
            }
    }
}

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
