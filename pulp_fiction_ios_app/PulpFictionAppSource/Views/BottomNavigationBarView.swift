//
//  NavigationBarView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/21/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer for navigating for the app's main pages
struct BottomNavigationBarViewReducer: ReducerProtocol {
    /// Signifies which app page is loaded into the main view
    enum MainView {
        case postFeedScrollView
        case loggedInUserProfileView
        case loggedInUserFollowedScrollView
    }

    /// The colors of the navigation bar symbols. Blue corresponds to the currently selected view.
    struct NavigationBarSymbolColor: Equatable {
        var postFeedScrollView: Color = .blue
        var loggedInUserProfileView: Color = .gray
        var loggedInUserFollowedScrollView: Color = .gray
    }

    struct State: Equatable {
        /// The page loaded into the main view
        var currentMainView: MainView = .postFeedScrollView
        /// The colors of the navigation bar symbols
        var navigationBarSymbolColor: NavigationBarSymbolColor = .init()
    }

    enum Action {
        /// Update State.currentMainView
        case updateCurrentNavigationView(MainView)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCurrentNavigationView(newMainView):
            state.currentMainView = newMainView
            updateNavigationBarSymbolColors(
                into: &state,
                newMainView: newMainView
            )
            return .none
        }
    }

    private func updateNavigationBarSymbolColors(into state: inout State, newMainView: MainView) {
        switch newMainView {
        case .postFeedScrollView:
            state.navigationBarSymbolColor.postFeedScrollView = .blue
            state.navigationBarSymbolColor.loggedInUserProfileView = .gray
            state.navigationBarSymbolColor.loggedInUserFollowedScrollView = .gray
        case .loggedInUserProfileView:
            state.navigationBarSymbolColor.postFeedScrollView = .gray
            state.navigationBarSymbolColor.loggedInUserProfileView = .blue
            state.navigationBarSymbolColor.loggedInUserFollowedScrollView = .gray
        case .loggedInUserFollowedScrollView:
            state.navigationBarSymbolColor.postFeedScrollView = .gray
            state.navigationBarSymbolColor.loggedInUserProfileView = .gray
            state.navigationBarSymbolColor.loggedInUserFollowedScrollView = .blue
        }
    }
}

/// View for a navigation bar at the bottom of the app. Used to navigate between the app's main pages.
struct BottomNavigationBarView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<BottomNavigationBarViewReducer> = Store(
        initialState: BottomNavigationBarViewReducer.State(),
        reducer: BottomNavigationBarViewReducer()
    )

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView { buildMainView(viewStore.state.currentMainView) }
            buildBottomNavigationBar(viewStore)
        }
    }

    @ViewBuilder private func buildMainView(_ currentMainView: BottomNavigationBarViewReducer.MainView) -> some View {
        switch currentMainView {
        case .postFeedScrollView:
            PostFeedScrollView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger
            )
        case .loggedInUserProfileView:
            UserProfileView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger
            )
        case .loggedInUserFollowedScrollView:
            UserConnectionsScrollView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger
            )
        }
    }

    @ViewBuilder private func buildBottomNavigationBar(_ viewStore: ViewStore<BottomNavigationBarViewReducer.State, BottomNavigationBarViewReducer.Action>) -> some View {
        HStack(alignment: .center) {
            Symbol(
                symbolName: "house",
                size: 28,
                color: viewStore.state.navigationBarSymbolColor.postFeedScrollView
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.postFeedScrollView))
            }
            Symbol(
                symbolName: "person.circle",
                size: 28,
                color: viewStore.state.navigationBarSymbolColor.loggedInUserProfileView
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.loggedInUserProfileView))
            }
            Symbol(
                symbolName: "person.2",
                size: 28,
                color: viewStore.state.navigationBarSymbolColor.loggedInUserFollowedScrollView
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.loggedInUserFollowedScrollView))
            }
        }
    }
}
