//
//  UserConnectionsTopFeedNavigationBarContents.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct UserConnectionsTopNavigationBarReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action {}

    func reduce(into _: inout State, action _: Action) -> EffectTask<Action> {
        return .none
    }
}

struct UserConnectionsTopNavigationBar: NavigationBarContents {
    var body: some View {
        HStack {
            Title("Following")
                .foregroundColor(.gray)
                .padding(.leading, 7.5)
            Spacer()
            Symbol(symbolName: "line.3.horizontal.decrease.circle", size: 25, color: .gray)
                .padding(.trailing, 7.5)
        }
    }
}
