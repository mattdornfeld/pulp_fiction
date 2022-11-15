//
//  LoggedInUserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct LoggedInUserProfileTopNavigationBarReducer: ReducerProtocol {
    struct State: Equatable {
        var shouldLoadPostCreatorView: Bool = false
    }

    enum Action {
        case updateShouldLoadPostCreatorView(Bool)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateShouldLoadPostCreatorView(newShouldLoadPostCreatorView):
            state.shouldLoadPostCreatorView = newShouldLoadPostCreatorView
            return .none
        }
    }
}

struct LoggedInUserProfileTopNavigationBar: ToolbarContent {
    let loggedInUserPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var viewStore: ViewStore<LoggedInUserProfileTopNavigationBarReducer.State, LoggedInUserProfileTopNavigationBarReducer.Action> = {
        let store = Store(
            initialState: LoggedInUserProfileTopNavigationBarReducer.State(),
            reducer: LoggedInUserProfileTopNavigationBarReducer()
        )

        return ViewStore(store)
    }()

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(loggedInUserPostData.userDisplayName)
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Symbol(
                    symbolName: "plus",
                    size: 20,
                    color: .gray
                ).navigateOnTap(
                    isActive: viewStore.binding(
                        get: \.shouldLoadPostCreatorView,
                        send: LoggedInUserProfileTopNavigationBarReducer.Action.updateShouldLoadPostCreatorView(false)
                    ),
                    destination: PostCreatorView(
                        loggedInUserPostData: loggedInUserPostData,
                        postFeedMessenger: postFeedMessenger
                    )
                ) {
                    viewStore.send(.updateShouldLoadPostCreatorView(true))
                }

                Symbol(symbolName: "gearshape.fill", size: 20, color: .gray)
            }
        }
    }
}
