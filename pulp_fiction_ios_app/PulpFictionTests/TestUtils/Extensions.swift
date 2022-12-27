//
//  Extensions.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import ComposableArchitecture
import Foundation
import XCTest

@testable import PulpFictionAppSource

extension BackendMessenger {
    func getPulpFictionTestClientWithFakeData() -> PulpFictionTestClientWithFakeData {
        pulpFictionClientProtocol as! PulpFictionTestClientWithFakeData
    }
}

extension ComposableArchitecture.ViewStore where ViewState: Equatable {
    /// Listen on the ViewStore publisher for a state update and asserts the update is as expected
    /// - Parameters:
    ///   - durationMaybe: how long to wait for the state update
    ///   - expectedStateSupplier: closure that supplies the expected state
    func assertStateChange(for durationMaybe: TimeInterval? = 0.1, expectedStateSupplier: () -> ViewState) {
        let viewStateQueue = Queue<ViewState>(maxSize: 1)
        publisher
        publisher
            .sink(receiveValue: { state in
                viewStateQueue.enqueue(state)
            })
        XCTAssertEqual(expectedStateSupplier(), viewStateQueue.dequeue(for: durationMaybe))
    }
}
