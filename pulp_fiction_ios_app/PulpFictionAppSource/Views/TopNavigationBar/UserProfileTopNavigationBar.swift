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

struct UserProfileTopNavigationBar: NavigationBarContents {
    let userPostData: UserPostData

    var body: some View {
        HStack {
            Title(userPostData.userDisplayName)
                .foregroundColor(.gray)
                .padding(.leading, 7.5)
            Spacer()
            Symbol(symbolName: "plus", size: 25, color: .gray)
            Symbol(symbolName: "gearshape.fill", size: 25, color: .gray)
                .padding(.trailing, 7.5)
        }
    }
}
