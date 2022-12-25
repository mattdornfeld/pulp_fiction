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
struct BottomNavigationBarReducer: ReducerProtocol {
    /// Signifies which app page is loaded into the main view
    enum MainView {
        case postFeedScrollView
        case loggedInUserProfileView
        case loggedInUserFollowedScrollView
    }

    struct State: Equatable {
        /// The page loaded into the main view
        var currentMainView: MainView

        func getNavigationBarSymbolColor(mainView: MainView) -> Color {
            if mainView == currentMainView {
                return .blue
            }
            return .gray
        }
    }

    enum Action {
        /// Update State.currentMainView
        case updateCurrentNavigationView(MainView)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateCurrentNavigationView(newMainView):
            state.currentMainView = newMainView
            return .none
        }
    }
}

/// View for a navigation bar at the bottom of the app. Used to navigate between the app's main pages.
struct BottomNavigationBarView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    let backendMessenger: BackendMessenger
    let notificationBannerViewStore: NotificationnotificationBannerViewStore
    @ObservedObject private var viewStore: ViewStore<BottomNavigationBarReducer.State, BottomNavigationBarReducer.Action>

    init(
        loggedInUserPostData: UserPostData,
        postFeedMessenger: PostFeedMessenger,
        backendMessenger: BackendMessenger,
        notificationBannerViewStore: NotificationnotificationBannerViewStore,
        currentMainView: BottomNavigationBarReducer.MainView = .postFeedScrollView
    ) {
        self.loggedInUserPostData = loggedInUserPostData
        self.postFeedMessenger = postFeedMessenger
        self.backendMessenger = backendMessenger
        self.notificationBannerViewStore = notificationBannerViewStore
        viewStore = {
            let store = Store(
                initialState: BottomNavigationBarReducer.State(currentMainView: currentMainView),
                reducer: BottomNavigationBarReducer()
            )
            return ViewStore(store)
        }()
    }

    var body: some View {
        VStack {
            buildMainView(viewStore.state.currentMainView)
            buildBottomNavigationBar(viewStore)
        }
        .accentColor(.black)
    }

    @ViewBuilder private func buildMainView(_ currentMainView: BottomNavigationBarReducer.MainView) -> some View {
        switch currentMainView {
        case .postFeedScrollView:
            PostFeedScrollView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        case .loggedInUserProfileView:
            UserProfileView(
                userProfileOwnerPostData: loggedInUserPostData,
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        case .loggedInUserFollowedScrollView:
            UserConnectionsScrollView(
                loggedInUserPostData: loggedInUserPostData,
                postFeedMessenger: postFeedMessenger,
                backendMessenger: backendMessenger,
                notificationBannerViewStore: notificationBannerViewStore
            )
        }
    }

    @ViewBuilder private func buildBottomNavigationBar(_ viewStore: ViewStore<BottomNavigationBarReducer.State, BottomNavigationBarReducer.Action>) -> some View {
        HStack(alignment: .center) {
            Symbol(
                symbolName: "house",
                size: 28,
                color: viewStore.state.getNavigationBarSymbolColor(mainView: .postFeedScrollView)
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.postFeedScrollView))
            }
            Symbol(
                symbolName: "person.circle",
                size: 28,
                color: viewStore.state.getNavigationBarSymbolColor(mainView: .loggedInUserProfileView)
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.loggedInUserProfileView))
            }
            Symbol(
                symbolName: "person.2",
                size: 28,
                color: viewStore.state.getNavigationBarSymbolColor(mainView: .loggedInUserFollowedScrollView)
            )
            .padding(.horizontal)
            .padding(.bottom, 5)
            .onTapGesture {
                viewStore.send(.updateCurrentNavigationView(.loggedInUserFollowedScrollView))
            }
        }
    }
}
