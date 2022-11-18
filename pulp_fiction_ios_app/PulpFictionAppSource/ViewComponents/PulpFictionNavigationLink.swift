//
//  PulpFictionNavigationLink.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/16/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

// Reducer for PulpFictionNavigationLink
struct PulpFictionNavigationLinkReducer: ReducerProtocol {
    struct State: Equatable {
        /// If true will load the destination view passed to PulpFictionNavigationLink
        var shouldLoadDestinationView: Bool = false
    }

    enum Action {
        /// Updates shouldLoadDestinationView
        case updateShouldLoadDestinationView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadDestinationView(newShouldLoadDestinationView):
            state.shouldLoadDestinationView = newShouldLoadDestinationView
            return .none
        }
    }
}

/// Adds functionality that will navigate to destionation when the label view is tapped
struct PulpFictionNavigationLink<Label: View, Destination: View>: View {
    /// The label which the tap gesture is associated with
    let label: Label
    /// Supplier for the destination view which will be navigated to when label is tapped
    let destinationSupplier: () -> Destination
    private let store: ComposableArchitecture.StoreOf<PulpFictionNavigationLinkReducer> = Store(
        initialState: PulpFictionNavigationLinkReducer.State(),
        reducer: PulpFictionNavigationLinkReducer()
    )
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationLink(
                isActive: viewStore.binding(
                    get: \.shouldLoadDestinationView,
                    send: .updateShouldLoadDestinationView(false)
                ),
                destination: {
                    LazyView(destinationSupplier)
                        .navigationBarBackButtonHidden(true)
                        .navigationBarItems(leading: BackButton())
                },
                label: { label.onTapGesture(perform: { viewStore.send(.updateShouldLoadDestinationView(true)) }) }
            )
        }
    }
}

extension View {
    /// Associates a navigate on tap action with the view
    /// - Parameter destination: The Destination view which will be navigated to
    /// - Returns: A PulpFictionNavigationLink with this view as a label and destination as the destionation view
    func navigateOnTap<Destination: View>(
        destination: @autoclosure @escaping () -> Destination
    ) -> some View {
        PulpFictionNavigationLink(
            label: self,
            destinationSupplier: destination
        )
    }
}
