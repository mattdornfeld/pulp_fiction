//
//  SymbolWithDropDownMenu.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/24/22.
//
import Combine
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

    enum Action: Equatable {
        /// Called when a menu item is selected. Updates the current selection.
        case updateSelection(A)
        /// Runs dropDownMenuSelectionAction
        case runDropDownMenuSelectionAction(EquatableWrapper<() -> Void>)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateSelection(newSelection):
            state.currentSelection = newSelection
            let wrappedDropDownMenuSelectionAction = EquatableWrapper { self.dropDownMenuSelectionAction(newSelection) }
            return .task { .runDropDownMenuSelectionAction(wrappedDropDownMenuSelectionAction) }

        case let .runDropDownMenuSelectionAction(wrappedAction):
            wrappedAction.wrapped()
            return .none
        }
    }
}

extension ViewWithDropDownMenuReducer {
    init() {
        dropDownMenuSelectionAction = { _ in }
    }
}

/// View for a symbol with a selectable drop down menu
protocol ViewWithDropDownMenu: View {
    associatedtype A: DropDownMenuOption
    associatedtype Label: View
    var label: Label { get }
    var menuOptions: [A] { get }
    var viewStore: ViewStore<ViewWithDropDownMenuReducer<A>.State, ViewWithDropDownMenuReducer<A>.Action> { get set }
}

extension ViewWithDropDownMenu {
    @ViewBuilder var body: some View {
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

/// Associates a drop down menu with a symbol
struct SymbolWithDropDownMenuView<A: DropDownMenuOption>: ViewWithDropDownMenu {
    typealias A = A
    typealias Label = Symbol
    let label: Symbol
    let menuOptions: [A]
    private let store: PulpFictionStore<ViewWithDropDownMenuReducer<A>>
    @ObservedObject var viewStore: PulpFictionViewStore<ViewWithDropDownMenuReducer<A>>
}

extension SymbolWithDropDownMenuView {
    /// Constucts a SymbolWithDropDownMenu view
    /// - Parameters:
    ///   - symbolName: The SF symbol name
    ///   - symbolSize: The SF symbol size
    ///   - symbolColor: The SF symbol color
    ///   - menuOptions: An array of instances of DropDownMenuOption. These will be the options in the drop down menu
    ///   - store:An instance of PulpFictionStore
    ///   - dropDownMenuSelectionAction: A function to be called when a menu item is selected
    init(
        symbolName: String,
        symbolSize: CGFloat,
        symbolColor: Color,
        menuOptions: [A],
        store: PulpFictionStore<ViewWithDropDownMenuReducer<A>>,
        dropDownMenuSelectionAction _: @escaping (A) -> Void = { _ in }
    ) {
        self.menuOptions = menuOptions
        self.store = store
        label = Symbol(symbolName: symbolName, size: symbolSize, color: symbolColor)
        viewStore = ViewStore(store)
    }

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
        self.init(
            symbolName: symbolName,
            symbolSize: symbolSize,
            symbolColor: symbolColor,
            menuOptions: menuOptions,
            store: Store(
                initialState: .init(currentSelection: initialMenuSelection),
                reducer: ViewWithDropDownMenuReducer(dropDownMenuSelectionAction: dropDownMenuSelectionAction)
            )
        )
    }

//    init(
//        symbolName: String,
//        symbolSize: CGFloat,
//        symbolColor: Color,
//        menuOptions: [A],
//        viewStore: ViewStore<ViewWithDropDownMenuReducer<A>.State, ViewWithDropDownMenuReducer<A>.Action>
//    ) {
//        label = Symbol(symbolName: symbolName, size: symbolSize, color: symbolColor)
//        self.menuOptions = menuOptions
//        self.viewStore = viewStore
//    }
}

/// Associates a drop down menu with a text view
struct TextWithDropDownMenuView<A: DropDownMenuOption, B: TextView>: ViewWithDropDownMenu {
    typealias A = A
    typealias Label = B
    let label: B
    let menuOptions: [A]
    @ObservedObject var viewStore: ViewStore<ViewWithDropDownMenuReducer<A>.State, ViewWithDropDownMenuReducer<A>.Action>

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
        viewStore = {
            let store = Store(
                initialState: .init(currentSelection: initialMenuSelection),
                reducer: ViewWithDropDownMenuReducer(dropDownMenuSelectionAction: dropDownMenuSelectionAction)
            )
            return ViewStore(store)
        }()
    }
}

/// Base class for obserable classes containing drop down menu views and their ViewStores. These classes can be marked as ObservedObjects in other views to trigger upates when a menu selection occurs.
class DropDownMenuObservable<C: ViewWithDropDownMenu>: ObservableObject {
    let view: C
    var currentSelection: C.A { view.viewStore.currentSelection }
    private var cancellables: Set<AnyCancellable> = .init()
    @Published private var triggerUpdateToggle: Bool = false

    init(view: C) {
        self.view = view
        view.viewStore.publisher.sink(receiveValue: { _ in
            self.triggerUpdateToggle.toggle()
        }).store(in: &cancellables)
    }
}

/// Observable class for SymbolWithDropDownMenuView. Instantiate this in other views and use the attached view + viewStore properties.
class SymbolWithDropDownMenu<A: DropDownMenuOption>: DropDownMenuObservable<SymbolWithDropDownMenuView<A>> {
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
        super.init(view: SymbolWithDropDownMenuView(
            symbolName: symbolName,
            symbolSize: symbolSize,
            symbolColor: symbolColor,
            menuOptions: menuOptions,
            initialMenuSelection: initialMenuSelection,
            dropDownMenuSelectionAction: dropDownMenuSelectionAction
        ))
    }
}

/// Observable class for TextWithDropDownMenu. Instantiate this in other views and use the attached view + viewStore properties.
class TextWithDropDownMenu<A: DropDownMenuOption, B: TextView>: DropDownMenuObservable<TextWithDropDownMenuView<A, B>> {
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
        super.init(view: TextWithDropDownMenuView(
            textView: textView,
            menuOptions: menuOptions,
            initialMenuSelection: initialMenuSelection,
            dropDownMenuSelectionAction: dropDownMenuSelectionAction
        ))
    }
}
