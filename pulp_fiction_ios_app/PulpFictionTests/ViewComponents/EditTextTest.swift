//
//  EditTextTest.swift
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

@MainActor
class EditTextTest: XCTestCase {
    private let expectedMaxTestSize: Int = 100
    private func buildTestStore() -> PulpFictionTestStore<EditTextReducer> {
        TestStore(
            initialState: EditTextReducer.State(),
            reducer: EditTextReducer(
                maxTextSize: expectedMaxTestSize
            )
        )
    }

    func testUpdateText() async throws {
        let store = buildTestStore()
        let expectedText = "expectedText"
        await store.send(.updateText(expectedText)) {
            $0.text = expectedText
        }
    }

    func testMaxTextSize() async throws {
        let store = buildTestStore()
        let expectedText = (1 ... (expectedMaxTestSize + 1)).map { _ in "a" }.joined()
        await store.send(.updateText(expectedText)) {
            $0.text = String(expectedText.prefix(self.expectedMaxTestSize))
        }
    }
}
