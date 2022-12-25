//
//  Types.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/17/22.
//

import Bow
import ComposableArchitecture
import Foundation

/// Convenience type for specifying a TCA ViewStore
typealias PulpFictionViewStore<Reducer: ReducerProtocol> = ViewStore<Reducer.State, Reducer.Action>
/// Convenience type for specifying a TCA Store
typealias PulpFictionStore<Reducer: ReducerProtocol> = Store<Reducer.State, Reducer.Action>
/// Convenience type for specifying a Either<PulpFictionRequestError, A>
typealias PulpFictionRequestEither<A> = Either<PulpFictionRequestError, A>
