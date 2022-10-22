//
//  NavigationBarView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/21/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct NavigationBarViewReducer: ReducerProtocol {
    enum MainView {
        case postFeedScrollView
        case loggedInUserProfileView
        case loggedInUserFollowersScrollView
    }
    
    struct NavigationBarSymbolColor: Equatable {
        var postFeedScrollView: Color = .blue
        var loggedInUserProfileView: Color = .gray
        var loggedInUserFollowersScrollView: Color = .gray
    }
    
    struct State: Equatable {
        var currentMainView: MainView = .postFeedScrollView
        var navigationBarSymbolColor: NavigationBarSymbolColor = NavigationBarSymbolColor()

    }
    
    enum Action {
        case updateCurrentNavigationView(MainView)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .updateCurrentNavigationView(let newMainView):
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
            state.navigationBarSymbolColor.loggedInUserFollowersScrollView = .gray
        case .loggedInUserProfileView:
            state.navigationBarSymbolColor.postFeedScrollView = .gray
            state.navigationBarSymbolColor.loggedInUserProfileView = .blue
            state.navigationBarSymbolColor.loggedInUserFollowersScrollView = .gray
        case .loggedInUserFollowersScrollView:
            state.navigationBarSymbolColor.postFeedScrollView = .gray
            state.navigationBarSymbolColor.loggedInUserProfileView = .gray
            state.navigationBarSymbolColor.loggedInUserFollowersScrollView = .blue
        }
    }
}

struct NavigationBarView: View {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    private let store: ComposableArchitecture.StoreOf<NavigationBarViewReducer> = Store(
        initialState: NavigationBarViewReducer.State(),
        reducer: NavigationBarViewReducer()
    )
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView { buildMainView(viewStore.state.currentMainView) }
            
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
                    color: viewStore.state.navigationBarSymbolColor.loggedInUserFollowersScrollView
                )
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .onTapGesture {
                        viewStore.send(.updateCurrentNavigationView(.loggedInUserFollowersScrollView))
                    }
            }
        }
    }
    
    @ViewBuilder private func buildMainView(_ currentMainView: NavigationBarViewReducer.MainView) -> some View {
        switch currentMainView {
            case .postFeedScrollView:
                PostFeedScrollView(
                    postFeedMessenger: postFeedMessenger
                )
            case .loggedInUserProfileView:
                UserProfileView(
                    userPostData: loggedInUserPostData,
                    postFeedMessenger: postFeedMessenger
                )
            case .loggedInUserFollowersScrollView:
                PostFeedScrollView(
                    postFeedMessenger: postFeedMessenger
                )
            }
    }
}
