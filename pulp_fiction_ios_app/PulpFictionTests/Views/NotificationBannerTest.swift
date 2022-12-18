//
//  NotificationBannerTest.swift
//  _SwiftUINavigationState
//
//  Created by Matthew Dornfeld on 12/17/22.
//

import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppSource

@MainActor
class NotificationBannerTest: XCTestCase {
    private func getTestStore() -> PulpFictionTestStore<NotificationBannerReducer> {
        TestStore(
            initialState: NotificationBannerReducer.State(),
            reducer: NotificationBannerReducer()
        )
    }

    func testShowAndHideNotificationBanner() async throws {
        let expectedNotificationText = "testNotificationText"
        let store = getTestStore()
        await NotificationBannerReducer.BannerType.allCases.asyncForEach { expectedBannerType in
            await store.send(.showNotificationBanner(expectedNotificationText, expectedBannerType)) {
                $0.shouldShowNotification = true
                $0.notificationTextMaybe = expectedNotificationText
                $0.bannerTypeMaybe = expectedBannerType
            }

            XCTAssertEqual(expectedNotificationText, store.state.getNotificationTextOrDefault())
            XCTAssertEqual(expectedBannerType, store.state.getBannerTypeOrDefault())

            await store.send(.hideNotificationBanner) {
                $0.shouldShowNotification = false
                $0.notificationTextMaybe = nil
                $0.bannerTypeMaybe = nil
            }

            XCTAssertEqual("", store.state.getNotificationTextOrDefault())
            XCTAssertEqual(NotificationBannerReducer.BannerType.info, store.state.getBannerTypeOrDefault())
        }
    }
}
