//
//  TCAExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/24/22.
//

import ComposableArchitecture
import Foundation

extension ViewStore {
    convenience init<Reducer: ReducerProtocol>(initialState: Reducer.State, reducer: Reducer) where ViewState == Reducer.State, ViewAction == Reducer.Action, ViewState: Equatable {
        let store = Store(
            initialState: initialState,
            reducer: reducer
        )
        self.init(store)
    }
}
