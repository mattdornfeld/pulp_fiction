//
//  EmptyNavigationLinkView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/20/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for EmptyNavigationLinkView
struct EmptyNavigationLinkViewReducer: ReducerProtocol {
    struct State: Equatable {
        /// If true will load the destination view
        var shouldLoadDestionationView: Bool = false
    }

    enum Action: Equatable {
        /// Updates shouldLoadDestionationView
        case navigateToDestionationView(EquatableIgnore<() -> Void> = .init(wrappedValue: {}))
        case updateShouldLoadDestionationView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .navigateToDestionationView(wrappedCallback):
            wrappedCallback.wrappedValue()
            return .task { .updateShouldLoadDestionationView(true) }

        case let .updateShouldLoadDestionationView(newShouldLoadDestionationView):
            state.shouldLoadDestionationView = newShouldLoadDestionationView
            return .none
        }
    }
}

/// View that contains a NavigationLink with an empty label. Useful for when you want to trigger navigation through an indirect action.
struct EmptyNavigationLinkView<Destination: View>: View {
    /// The destination View
    let destination: Destination
    let hideBackButton: Bool
    let store: PulpFictionStore<EmptyNavigationLinkViewReducer>
    /// ViewStore for this object
    @ObservedObject var viewStore: EmptyNavigationLinkViewStore = EmptyNavigationLinkView.buildViewStore()

    var body: some View {
        NavigationLink(
            destination: buildDestination(),
            isActive: viewStore.binding(
                get: \.shouldLoadDestionationView,
                send: .updateShouldLoadDestionationView(false)
            )
        ) { EmptyView() }
    }

    @ViewBuilder private func buildDestination() -> some View {
        let _destination = destination
            .navigationBarBackButtonHidden(true)

        if hideBackButton {
            _destination
        } else {
            _destination.navigationBarItems(leading: BackButton())
        }
    }

    static func buildViewStore() -> EmptyNavigationLinkViewStore {
        .init(
            initialState: EmptyNavigationLinkViewReducer.State(),
            reducer: EmptyNavigationLinkViewReducer()
        )
    }
}

extension EmptyNavigationLinkView {
    init(
        store: PulpFictionStore<EmptyNavigationLinkViewReducer>,
        hideBackButton: Bool = false,
        destinationSupplier: () -> Destination
    ) {
        self.store = store
        self.hideBackButton = hideBackButton
        destination = destinationSupplier()
        viewStore = ViewStore(store)
    }

    init(hideBackButton: Bool = false, destination: Destination) {
        self.init(
            store: .init(
                initialState: .init(),
                reducer: EmptyNavigationLinkViewReducer()
            ),
            hideBackButton: hideBackButton,
            destinationSupplier: { destination }
        )
    }

    init(hideBackButton: Bool = false, destinationSupplier: () -> Destination) {
        self.init(
            store: .init(
                initialState: .init(),
                reducer: EmptyNavigationLinkViewReducer()
            ),
            hideBackButton: hideBackButton,
            destinationSupplier: destinationSupplier
        )
    }
}

/// Convenience type for ViewStore<EmptyNavigationLinkViewReducer.State, EmptyNavigationLinkViewReducer.Action>
typealias EmptyNavigationLinkViewStore = ViewStore<EmptyNavigationLinkViewReducer.State, EmptyNavigationLinkViewReducer.Action>

/// ObservableObject class that contains a EmptyNavigationLinkView and its ViewStore. Useful for when you want to update a parent view when navigation is triggered.
class EmptyNavigationLink<Destination: View>: ObservableObject {
    /// The view for the EmptyNavigationLink. This has to be specified somewhere inside of the NavigationView for the navigation action to take effect.
    let view: EmptyNavigationLinkView<Destination>
    /// The ViewStore for the EmptyNavigationLinkView. This decorated with the Published property, so changes to the ViewStore can trigger a change in parent views.
    @Published var viewStore: EmptyNavigationLinkViewStore

    /// Inits a EmptyNavigationLink
    /// - Parameter destination: The Destination view
    init(hideBackButton: Bool = false, destination: Destination) {
        view = EmptyNavigationLinkView(
            hideBackButton: hideBackButton,
            destination: destination
        )
        viewStore = view.viewStore
    }

    convenience init(hideBackButton: Bool = false, destinationSupplier: () -> Destination) {
        self.init(
            hideBackButton: hideBackButton,
            destination: destinationSupplier()
        )
    }
}
