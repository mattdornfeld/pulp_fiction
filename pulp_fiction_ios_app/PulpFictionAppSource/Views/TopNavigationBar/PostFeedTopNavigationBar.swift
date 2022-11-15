//
//  PostFeedTopNavigationBarView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct PostFeedTopNavigationBarReducer: ReducerProtocol {
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

struct PostFeedTopNavigationBar: ToolbarContent {
    let postFeedFilter: PostFeedFilter
    let dropDownMenuSelectionAction: (PostFeedFilter) -> Void
    let postFeedMessenger: PostFeedMessenger
    let loggedInUserPostData: UserPostData

    @ObservedObject private var viewStore: ViewStore<PostFeedTopNavigationBarReducer.State, PostFeedTopNavigationBarReducer.Action> = {
        let store = Store(
            initialState: PostFeedTopNavigationBarReducer.State(),
            reducer: PostFeedTopNavigationBarReducer()
        )

        return ViewStore(store)
    }()

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Title("Pulp Fiction")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 0.001) {
                Symbol(
                    symbolName: "plus",
                    size: 20,
                    color: .gray
                ).navigateOnTap(
                    isActive: viewStore.binding(
                        get: \.shouldLoadPostCreatorView,
                        send: PostFeedTopNavigationBarReducer.Action.updateShouldLoadPostCreatorView(false)
                    ),
                    destination: PostCreatorView(
                        loggedInUserPostData: loggedInUserPostData,
                        postFeedMessenger: postFeedMessenger
                    )
                ) {
                    viewStore.send(.updateShouldLoadPostCreatorView(true))
                }

                SymbolWithDropDownMenu(
                    symbolName: "line.3.horizontal.decrease.circle",
                    symbolSize: 20,
                    symbolColor: .gray,
                    menuOptions: PostFeedFilter.allCases,
                    initialMenuSelection: postFeedFilter,
                    dropDownMenuSelectionAction: dropDownMenuSelectionAction
                )
            }
        }
    }
}
