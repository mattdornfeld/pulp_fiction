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

    enum Action {
        /// Updates shouldLoadDestionationView
        case updateShouldLoadDestionationView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
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
    /// ViewStore for this object
    @ObservedObject var viewStore: ComposableArchitecture.ViewStore<EmptyNavigationLinkViewReducer.State, EmptyNavigationLinkViewReducer.Action> = {
        let store = Store(
            initialState: EmptyNavigationLinkViewReducer.State(),
            reducer: EmptyNavigationLinkViewReducer()
        )
        return ViewStore(store)
    }()

    var body: some View {
        NavigationLink(
            destination: destination.navigationBarBackButtonHidden(true),
            isActive: viewStore.binding(
                get: \.shouldLoadDestionationView,
                send: .updateShouldLoadDestionationView(false)
            )
        ) { EmptyView() }
    }
}

/// ObservableObject class that contains a EmptyNavigationLinkView and its ViewStore. Useful for when you want to update a parent view when navigation is triggered.
class EmptyNavigationLink<Destination: View>: ObservableObject {
    /// The view for the EmptyNavigationLink. This has to be specified somewhere inside of the NavigationView for the navigation action to take effect.
    let view: EmptyNavigationLinkView<Destination>
    /// The ViewStore for the EmptyNavigationLinkView. This decorated with the Published property, so changes to the ViewStore can trigger a change in parent views.
    @Published var viewStore: ComposableArchitecture.ViewStore<EmptyNavigationLinkViewReducer.State, EmptyNavigationLinkViewReducer.Action>

    /// Inits a EmptyNavigationLink
    /// - Parameter destination: The Destination view
    init(destination: Destination) {
        view = EmptyNavigationLinkView(destination: destination)
        viewStore = view.viewStore
    }
}
