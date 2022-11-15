//
//  UserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct UserProfileTopNavigationBarReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action {}

    func reduce(into _: inout State, action _: Action) -> EffectTask<Action> {
        return .none
    }
}

struct UserProfileTopNavigationBar: ToolbarContent {
    let userProfileOwnerPostData: UserPostData
    let postFeedMessenger: PostFeedMessenger
    @ObservedObject private var viewStore: ViewStore<UserProfileTopNavigationBarReducer.State, UserProfileTopNavigationBarReducer.Action> = {
        let store = Store(
            initialState: UserProfileTopNavigationBarReducer.State(),
            reducer: UserProfileTopNavigationBarReducer()
        )

        return ViewStore(store)
    }()

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(userProfileOwnerPostData.userDisplayName)
                .foregroundColor(.gray)
        }
    }
}
