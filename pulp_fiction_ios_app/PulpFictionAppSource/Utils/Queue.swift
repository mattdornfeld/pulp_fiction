//
//  Queue.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/29/22.
//

import Foundation
import Logging

/// Thread safe implementation of queue with a maxSize property
public class Queue<A> {
    public let maxSize: Int
    private let queue = DispatchQueue(label: "queue.operations")
    private let logger = Logger(label: String(describing: Queue.self))
    private var elements: [A] = []
    private var isClosed: NSConditionLock = .init(condition: 0)
    private var isEmpty: NSConditionLock = .init(condition: 1)
    private var isFull: NSConditionLock = .init(condition: 0)

    public init(maxSize: Int) {
        self.maxSize = maxSize
    }

    public func getSize() -> Int {
        queue.sync {
            elements.count
        }
    }

    public func checkLockedBecauseEmpty() -> Bool {
        isEmpty.condition == 1
    }

    public func checkLockedBecauseFull() -> Bool {
        isFull.condition == 1
    }

    @discardableResult
    public func enqueue(_ value: A) -> Queue<A> {
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

    public func close() {
        isClosed.unlock(withCondition: 1)
        isEmpty.unlock(withCondition: 0)
        logger.debug("Queue is closed")
    }

    public func dequeue() -> A? {
        logger.debug("Dequeueing element")
        isEmpty.lock(whenCondition: 0)

        if isClosed.tryLock(whenCondition: 1) {
            logger.debug("Dequeueing element from closed queue")
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
