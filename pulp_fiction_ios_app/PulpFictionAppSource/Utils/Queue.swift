//
//  Queue.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/29/22.
//

import Foundation
import Logging

/// Thread safe implementation of queue with a maxSize property
public class Queue<A>: Equatable where A: Equatable {
    public let maxSize: Int
    private let queue = DispatchQueue(label: "queue.operations")
    private let logger = Logger(label: String(describing: Queue.self))
    private var elements: [A] = []
    private var isClosed: AtomicBoolean = .init(value: false)
    private var isEmpty: NSConditionLock = .init(condition: 1)
    private var isFull: NSConditionLock = .init(condition: 0)

    public init(maxSize: Int) {
        self.maxSize = maxSize
    }

    public static func == (lhs: Queue<A>, rhs: Queue<A>) -> Bool {
        lhs.elements == rhs.elements
            && lhs.maxSize == rhs.maxSize
            && lhs.isClosed == rhs.isClosed
            && lhs.isEmpty == rhs.isEmpty
            && lhs.isFull == rhs.isFull
    }

    public func getSize() -> Int {
        queue.sync {
            elements.count
        }
    }

    /// Returns true if queue is locked because it's empty
    public func checkLockedBecauseEmpty() -> Bool {
        isEmpty.condition == 1
    }

    /// Returns true if queue is locked because it's full
    public func checkLockedBecauseFull() -> Bool {
        isFull.condition == 1
    }

    /// Enqueue an element to the queue. Blocks if full. No-op if closed.
    @discardableResult
    public func enqueue(_ value: A) -> Queue<A> {
        if isClosed.getValue() {
            logger.debug("Attempted to enqueue element to closed queue")
            return self
        }

        logger.debug("Enqueueing element")
        isFull.lock(whenCondition: 0)

        queue.sync {
            self.elements.append(value)
        }

        isEmpty.unlock(withCondition: 0)
        if getSize() == maxSize {
            isFull.unlock(withCondition: 1)
        }

        logger.debug("Finished Enqueueing element")
        return self
    }

    /// Closes the queue. No new elements can be enqueued or dequeued.
    public func close() {
        isClosed.setValue(true)
        isEmpty.unlock(withCondition: 0)
        logger.debug("Queue is closed")
    }

    /// Dequeues an element from the queue. Blocks if empty. No-op if closed.
    public func dequeue() -> A? {
        if isClosed.getValue() {
            logger.debug("Attempted to dequeue element from closed queue")
            return nil
        }

        logger.debug("Dequeueing element")
        isEmpty.lock(whenCondition: 0)

        // Check if closed a second time in case queue is closed while stuck in above lock
        if isClosed.getValue() {
            return nil
        }

        let element = queue.sync {
            self.elements.removeFirst()
        }

        isFull.unlock(withCondition: 0)
        if getSize() == 0 {
            isEmpty.unlock(withCondition: 1)
        }

        logger.debug("Finished dequeueing element")

        return element
    }
}
