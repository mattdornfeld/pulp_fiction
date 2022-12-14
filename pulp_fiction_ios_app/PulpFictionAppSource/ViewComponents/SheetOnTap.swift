//
//  SheetOnTap.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/19/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for SheetOnTap
struct SheetOnTapReducer: ReducerProtocol {
    struct State: Equatable {
        /// If true will load sheet
        var shouldLoadSheet: Bool = false
    }

    enum Action {
        /// Updates shouldLoadSheet
        case updateShouldLoadSheet(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadSheet(newShouldLoadSheet):
            state.shouldLoadSheet = newShouldLoadSheet
            return .none
        }
    }
}

/// View that loads a sheet with content when the label is tapped
struct SheetOnTap<Label: View, SheetContent: View>: View {
    /// Label to associate tap action with
    let label: Label
    /// Function that supplies the sheet content
    let sheetContentSupplier: () -> SheetContent
    private let store: ComposableArchitecture.StoreOf<SheetOnTapReducer> = Store(
        initialState: SheetOnTapReducer.State(),
        reducer: SheetOnTapReducer()
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            label.onTapGesture {
                viewStore.send(.updateShouldLoadSheet(true))
            }.sheet(
                isPresented: viewStore.binding(
                    get: \.shouldLoadSheet,
                    send: .updateShouldLoadSheet(false)
                ),
                content: sheetContentSupplier
            )
        }
    }
}

extension View {
    /// Fluent method that associates an action with a label that loads a sheet when it is tapped
    /// - Parameter sheetContentSupplier: Function that supplies the sheet content
    /// - Returns: The label with the tap action associated with it
    func sheetOnTap<SheetContent: View>(sheetContentSupplier: @escaping () -> SheetContent) -> some View {
        SheetOnTap(label: self, sheetContentSupplier: sheetContentSupplier)
    }
}
