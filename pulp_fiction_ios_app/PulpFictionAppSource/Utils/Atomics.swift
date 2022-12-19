//
//  AtomicCounter.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/5/22.
//

import Foundation

/// Atomic integer counter
public class AtomicCounter {
    private var queue = DispatchQueue(label: "atomic.counter")
    private var value: Int = 0

    func increment() {
        queue.sync {
            self.value += 1
        }
    }

    func getValue() -> Int {
        queue.sync {
            self.value
        }
    }
}

/// Atomic boolean
public class AtomicBoolean: Equatable {
    private var queue = DispatchQueue(label: "atomic.boolean")
    private var value: Bool

    init(value: Bool) {
        self.value = value
    }

    public static func == (lhs: AtomicBoolean, rhs: AtomicBoolean) -> Bool {
        lhs.getValue() == rhs.getValue()
    }

    func setValue(_ newValue: Bool) {
        queue.sync {
            value = newValue
        }
    }

    func getValue() -> Bool {
        queue.sync {
            value
        }
    }
}
