//
//  EquatableClosure.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/19/22.
//

import Foundation

/// Wraps a closure with 0 arguments in an Equatable object where == always returns true
struct EquatableClosure0<A>: Equatable {
    let closure: () -> A

    static func == (_: EquatableClosure0<A>, _: EquatableClosure0<A>) -> Bool {
        return true
    }

    func callAsFunction() -> A {
        closure()
    }
}
