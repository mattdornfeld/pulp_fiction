//
//  Types.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/17/22.
//

import ComposableArchitecture
import Foundation

/// Convenience type for declaring a TestStore
typealias PulpFictionTestStore<Reducer: ReducerProtocol> = TestStore<Reducer.State, Reducer.Action, Reducer.State, Reducer.Action, Void>
