//
//  ContentScrollViewTest.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import Bow
import ComposableArchitecture
import Foundation
import SwiftUI
import XCTest

@testable import PulpFictionAppPreview
@testable import PulpFictionAppSource

// @MainActor
class ContentScrollViewTest: XCTestCase {
    @MainActor
    private func buildPostFeedScrollView() throws -> PostFeedScrollView {
        let userPostDataEither = Either<PulpFictionRequestError, UserPostData>.var()
        let externalMessengersEither = Either<PulpFictionRequestError, ExternalMessengers>.var()

        return try binding(
            userPostDataEither <- UserPostData
                .generate()
                .unsafeRunSyncEither(),
            externalMessengersEither <- ExternalMessengers
                .createForTests()
                .logError("Error creating ExternalMessengers")
                .mapLeft { PulpFictionRequestError($0) },
            yield: PostFeedScrollView(
                loggedInUserPostData: userPostDataEither.get,
                postFeedMessenger: externalMessengersEither.get.postFeedMessenger,
                backendMessenger: externalMessengersEither.get.backendMessenger,
                notificationBannerViewStore: NotificationBanner.buildViewStore()
            )
        )^.getOrThrow()
    }

    func testPostsAreEnqueuedProperlyOnInit() async throws {
        let contentScrollView = try await buildPostFeedScrollView().contentScrollView
        let postViews = await contentScrollView
            .viewStore
            .state
            .postViews
            .dequeue(numElements: PostFeedConfigs.numPostReturnedPerRequest, for: 5)

        XCTAssertEqual(PostFeedConfigs.numPostReturnedPerRequest, postViews.count)
        XCTAssertEqual(Array(1 ... PostFeedConfigs.numPostReturnedPerRequest), postViews.map { $0.id })

        DispatchQueue.main.sync {
            contentScrollView.viewStore.send(.stopScroll)
        }
    }

    func testRefreshScrollIfNecessary() async throws {
        let contentScrollView = try await buildPostFeedScrollView().contentScrollView
        DispatchQueue.main.sync {
            contentScrollView.viewStore.send(.refreshScrollIfNecessary(PostFeedConfigs.numPostReturnedPerRequest))
        }

        let expectedNumPostViews = 2 * PostFeedConfigs.numPostReturnedPerRequest
        let postViews = await contentScrollView
            .viewStore
            .state
            .postViews
            .dequeue(numElements: expectedNumPostViews, for: 5)

        XCTAssertEqual(expectedNumPostViews, postViews.count)
        XCTAssertEqual(Array(1 ... expectedNumPostViews), postViews.map { $0.id })

        DispatchQueue.main.sync {
            contentScrollView.viewStore.send(.stopScroll)
        }
    }

    func testDequeuePostsFromScrollIfNecessary() async throws {
        let contentScrollView = try await buildPostFeedScrollView().contentScrollView
        let numRefreshes = PostFeedConfigs.postFeedMaxQueueSize / PostFeedConfigs.numPostReturnedPerRequest - 1
        await (1 ... numRefreshes).asyncForEach { n in
            await DispatchQueue.main.sync {
                contentScrollView.viewStore.send(.refreshScrollIfNecessary(n * PostFeedConfigs.numPostReturnedPerRequest))
            }.finish()
            Thread.sleep(forTimeInterval: 0.5)
        }

        await assertPostViewIdsAreEqualToExpected(
            Array(1 ... PostFeedConfigs.postFeedMaxQueueSize),
            contentScrollView.viewStore
        )

        await DispatchQueue.main.sync {
            contentScrollView.viewStore.send(.refreshScrollIfNecessary((numRefreshes + 1) * PostFeedConfigs.numPostReturnedPerRequest))
        }.finish()
        Thread.sleep(forTimeInterval: 0.5)

        await assertPostViewIdsAreEqualToExpected(
            Array((PostFeedConfigs.numPostReturnedPerRequest + 1) ... (PostFeedConfigs.postFeedMaxQueueSize + PostFeedConfigs.numPostReturnedPerRequest)),
            contentScrollView.viewStore
        )
    }

    private func assertPostViewIdsAreEqualToExpected(
        _ expectedPostViewIds: [Int],
        _ viewStore: PulpFictionViewStore<ContentScrollViewReducer<ImagePostView>>
    ) {
        let postViewIds = viewStore.postViews.elements.map { $0.id }
        XCTAssertEqual(
            expectedPostViewIds,
            postViewIds
        )
    }
}
