//
//  Types.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/17/22.
//

import ComposableArchitecture
import Foundation

/// Convenience type for specifying ViewStores
typealias PulpFictionViewStore<Reducer: ReducerProtocol> = ViewStore<Reducer.State, Reducer.Action>
