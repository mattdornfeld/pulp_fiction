//
//  Queue.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/29/22.
//

import Foundation
import Logging

private extension NSConditionLock {
    func lockForDuration(whenCondition condition: Int, for durationMaybe: TimeInterval? = nil) {
        durationMaybe
            .map { lock(whenCondition: condition, before: Date.now.advanced(by: $0)) }
            .orElse { lock(whenCondition: condition) }
    }

    func lockForDuration(for durationMaybe: TimeInterval? = nil) {
        durationMaybe
            .map { lock(before: Date.now.advanced(by: $0)) }
            .orElse { lock() }
    }
}

/// Thread safe implementation of queue with a maxSize property
class Queue<A>: Equatable where A: Equatable {
    let maxSize: Int
    private let queue = DispatchQueue(label: "queue.operations")
    private let logger = Logger(label: String(describing: Queue.self))
    private(set) var elements: [A] = []
    private var isClosedAtomicBoolean: AtomicBoolean = .init(value: false)
    private var isEmpty: NSConditionLock = .init(condition: 1)
    private var isFull: NSConditionLock = .init(condition: 0)

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    static func == (lhs: Queue<A>, rhs: Queue<A>) -> Bool {
        lhs.elements == rhs.elements
            && lhs.maxSize == rhs.maxSize
            && lhs.isClosedAtomicBoolean == rhs.isClosedAtomicBoolean
            && lhs.isEmpty == rhs.isEmpty
            && lhs.isFull == rhs.isFull
    }

    func getSize() -> Int {
        queue.sync {
            elements.count
        }
    }

    /// Returns true if queue is locked because it's empty
    func checkLockedBecauseEmpty() -> Bool {
        isEmpty.condition == 1
    }

    /// Returns true if queue is locked because it's full
    func checkLockedBecauseFull() -> Bool {
        isFull.condition == 1
    }

    /// Enqueue a elements to the queue. Blocks if full. No-op if closed.
    @discardableResult
    func enqueue(_ value: A, for durationMaybe: TimeInterval? = nil) -> Queue<A> {
        enqueue([value], for: durationMaybe)
    }

    /// Enqueue a elements to the queue. Blocks if full. No-op if closed.
    @discardableResult
    func enqueue(_ values: [A], for durationMaybe: TimeInterval? = nil) -> Queue<A> {
        if isClosedAtomicBoolean.getValue() {
            logger.debug("Attempted to enqueue element to closed queue")
            return self
        }

        logger.debug(
            "Enqueueing elements",
            metadata: [
                "lockedBecauseEmpty": "\(checkLockedBecauseEmpty())",
                "lockedBecauseFull": "\(checkLockedBecauseFull())",
                "count": "\(elements.count)",
                "maxSize": "\(maxSize)",
                "numElements": "\(values.count)",
            ]
        )

        isFull.lockForDuration(whenCondition: 0, for: durationMaybe)
        isEmpty.lockForDuration(for: durationMaybe)
        values.map { self.elements.append($0) }

        isEmpty.unlock(withCondition: 0)
        if getSize() >= maxSize {
            isFull.unlock(withCondition: 1)
        } else {
            isFull.unlock(withCondition: 0)
        }

        logger.debug(
            "Finished enqueueing elements",
            metadata: [
                "lockedBecauseEmpty": "\(checkLockedBecauseEmpty())",
                "lockedBecauseFull": "\(checkLockedBecauseFull())",
                "count": "\(elements.count)",
                "maxSize": "\(maxSize)",
                "numElements": "\(values.count)",
            ]
        )
        return self
    }

    /// Closes the queue. No new elements can be enqueued or dequeued.
    func close() -> Queue<A> {
        isClosedAtomicBoolean.setValue(true)
        isEmpty.unlock(withCondition: 0)
        logger.debug("Queue is closed")
        return self
    }

    /// Returns true if queue is closed
    func isClosed() -> Bool {
        return isClosedAtomicBoolean.getValue()
    }

    /// Dequeues elements from the queue. Blocks if empty. No-op if closed.
    @discardableResult
    func dequeue(numElements: Int, for durationMaybe: TimeInterval? = nil) -> [A] {
        (1 ... numElements)
            .map { _ in dequeue(for: durationMaybe).toOption() }
            .flattenOption()
    }

    /// Dequeues an element from the queue. Blocks if empty. No-op if closed.
    @discardableResult
    func dequeue(for durationMaybe: TimeInterval? = nil) -> A? {
        if isClosedAtomicBoolean.getValue() {
            logger.debug("Attempted to dequeue element from closed queue")
            return nil
        }

        logger.debug(
            "Dequeueing elements",
            metadata: [
                "lockedBecauseEmpty": "\(checkLockedBecauseEmpty())",
                "lockedBecauseFull": "\(checkLockedBecauseFull())",
                "count": "\(elements.count)",
                "maxSize": "\(maxSize)",
            ]
        )
        isEmpty.lockForDuration(whenCondition: 0, for: durationMaybe)
        isFull.lockForDuration(for: durationMaybe)

        // Check if closed a second time in case queue is closed while stuck in above lock
        if isClosedAtomicBoolean.getValue() {
            return nil
        }

        let element = elements.removeFirst()

        isFull.unlock(withCondition: 0)
        if getSize() == 0 {
            isEmpty.unlock(withCondition: 1)
        } else {
            isEmpty.unlock(withCondition: 0)
        }

        logger.debug(
            "Finished dequeueing elements",
            metadata: [
                "lockedBecauseEmpty": "\(checkLockedBecauseEmpty())",
                "lockedBecauseFull": "\(checkLockedBecauseFull())",
                "count": "\(elements.count)",
                "maxSize": "\(maxSize)",
            ]
        )

        return element
    }
}
