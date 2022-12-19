//
//  QueueTest.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/1/22.
//

import Foundation
import XCTest

@testable import PulpFictionAppSource

class QueueTests: XCTestCase {
    func testQueueEmptyWhenCreated() {
        let queue = Queue<Int>(maxSize: 1)
        XCTAssertEqual(0, queue.getSize())
        XCTAssertTrue(queue.checkLockedBecauseEmpty())
        XCTAssertFalse(queue.checkLockedBecauseFull())
    }

    func testEnqueueAndDequeue() {
        let expectedElement = 2
        let element = Queue<Int>(maxSize: 1)
            .enqueue(expectedElement)
            .dequeue()

        XCTAssertEqual(expectedElement, element)
    }

    func testQueueLocksWhenFull() {
        let expectedMaxSize = 1
        let queue = Queue<Int>(maxSize: expectedMaxSize)
            .enqueue(1)

        XCTAssertEqual(expectedMaxSize, queue.maxSize)
        XCTAssertEqual(expectedMaxSize, queue.getSize())
        XCTAssertTrue(queue.checkLockedBecauseFull())
        XCTAssertFalse(queue.checkLockedBecauseEmpty())
    }

    func testOverfillingQueue() {
        let expectedElements = [1, 2, 3]
        let elements = Queue<Int>(maxSize: 2)
            .enqueue(expectedElements)
            .dequeue(numElements: 3)

        XCTAssertEqual(expectedElements, elements)
    }

    func testClosingQueue() {
        let queue = Queue<Int>(maxSize: 2)
            .enqueue([1, 2])
            .close()

        XCTAssertTrue(queue.isClosed())
        XCTAssertEqual(nil, queue.dequeue())
        XCTAssertEqual(queue, queue.enqueue(3))
    }
}
