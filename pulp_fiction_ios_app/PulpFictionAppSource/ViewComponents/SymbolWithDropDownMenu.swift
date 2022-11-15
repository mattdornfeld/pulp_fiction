//
//  SymbolWithDropDownMenu.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/24/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Inherited by enums that are passed to menuOptions in SymbolWithDropDownMenu
protocol DropDownMenuOption: CaseIterable, Hashable, Equatable, RawRepresentable<String> {}

/// Reducer for SymbolWithDropDownMenu
struct ViewWithDropDownMenuReducer<A: DropDownMenuOption>: ReducerProtocol {
    /// A function to be called when a menu item is selected
    let dropDownMenuSelectionAction: (A) -> Void

    struct State: Equatable {
        /// Current menu selection for the drop down menu
        var currentSelection: A
    }

    enum Action {
        /// Called when a menu item is selected. Updates the current selection.
        case updateSelection(A)
        /// Runs dropDownMenuSelectionAction
        case runDropDownMenuSelectionAction(() -> Void)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateSelection(newSelection):
            state.currentSelection = newSelection
            return .task { .runDropDownMenuSelectionAction { dropDownMenuSelectionAction(newSelection) } }

        case let .runDropDownMenuSelectionAction(action):
            action()
            return .none
        }
    }
}

/// View for a symbol with a selectable drop down menu
protocol ViewWithDropDownMenu: View {
    associatedtype A: DropDownMenuOption
    associatedtype Label: View
    var label: Label { get }
    var menuOptions: [A] { get }
    var store: ComposableArchitecture.StoreOf<ViewWithDropDownMenuReducer<A>> { get }
}

extension ViewWithDropDownMenu {
    var body: some View {
        WithViewStore(store) { viewStore in
            Menu {
                Picker(selection: viewStore.binding(
                    get: { state in state.currentSelection },
                    send: { newSelection in .updateSelection(newSelection) }
                ), label: EmptyView()) {
                    ForEach(menuOptions, id: \.self) {
                        Text($0.rawValue)
                    }
                }
            } label: {
                label
            }
        }
    }
}

struct SymbolWithDropDownMenu<A: DropDownMenuOption>: ViewWithDropDownMenu {
    typealias A = A
    typealias Label = Symbol
    let label: Symbol
    let menuOptions: [A]
    let store: ComposableArchitecture.StoreOf<ViewWithDropDownMenuReducer<A>>

    /// Constucts a SymbolWithDropDownMenu view
    /// - Parameters:
    ///   - symbolName: The SF symbol name
    ///   - symbolSize: The SF symbol size
    ///   - symbolColor: The SF symbol color
    ///   - menuOptions: An array of instances of DropDownMenuOption. These will be the options in the drop down menu
    ///   - initialMenuSelection: The initial menu selection
    ///   - dropDownMenuSelectionAction: A function to be called when a menu item is selected
    init(
        symbolName: String,
        symbolSize: CGFloat,
        symbolColor: Color,
        menuOptions: [A],
        initialMenuSelection: A,
        dropDownMenuSelectionAction: @escaping (A) -> Void = { _ in }
    ) {
        label = Symbol(symbolName: symbolName, size: symbolSize, color: symbolColor)
        self.menuOptions = menuOptions
        store = Store(
            initialState: .init(currentSelection: initialMenuSelection),
            reducer: ViewWithDropDownMenuReducer(dropDownMenuSelectionAction: dropDownMenuSelectionAction)
        )
    }
}

struct TextWithDropDownMenu<A: DropDownMenuOption, B: TextView>: ViewWithDropDownMenu {
    typealias A = A
    typealias Label = B
    let label: B
    let menuOptions: [A]
    let store: ComposableArchitecture.StoreOf<ViewWithDropDownMenuReducer<A>>

    /// Constucts a TextWithDropDownMenu view
    /// - Parameters:
    ///   - textView: The text for the dropdown menu
    ///   - menuOptions: An array of instances of DropDownMenuOption. These will be the options in the drop down menu
    ///   - initialMenuSelection: The initial menu selection
    ///   - dropDownMenuSelectionAction: A function to be called when a menu item is selected
    init(
        textView: B,
        menuOptions: [A],
        initialMenuSelection: A,
        dropDownMenuSelectionAction: @escaping (A) -> Void = { _ in }
    ) {
        label = textView
        self.menuOptions = menuOptions
        store = Store(
            initialState: .init(currentSelection: initialMenuSelection),
            reducer: ViewWithDropDownMenuReducer(dropDownMenuSelectionAction: dropDownMenuSelectionAction)
        )
    }
}
