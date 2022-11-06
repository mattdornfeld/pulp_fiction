//
//  UserProfileTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
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
    let userPostData: UserPostData

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(userPostData.userDisplayName)
                .foregroundColor(.gray)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Symbol(symbolName: "plus", size: 20, color: .gray)
                Symbol(symbolName: "gearshape.fill", size: 20, color: .gray)
            }
        }
    }
}
