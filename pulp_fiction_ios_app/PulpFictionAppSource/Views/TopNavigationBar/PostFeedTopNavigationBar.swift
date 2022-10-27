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
    struct State: Equatable {}

    enum Action {}

    func reduce(into _: inout State, action _: Action) -> EffectTask<Action> {
        return .none
    }
}

struct PostFeedTopNavigationBar: NavigationBarContents {
    enum FeedFilter: String, DropDownMenuOption {
        case Global
        case Following
    }

    var body: some View {
        HStack {
            Title("Pulp Fiction")
                .foregroundColor(.gray)
                .padding(.leading, 7.5)
            Spacer()
            Symbol(symbolName: "plus", size: 25, color: .gray)
//            SymbolWithDropDownMenu(
//                symbolName: "line.3.horizontal.decrease.circle",
//                symbolSize: 25,
//                symbolColor: .gray,
//                menuOptions: FeedFilter.allCases,
//            ) { feedFilter in
//                switch feedFilter {
//                case .Global:
//                    print(FeedFilter.Global)
//                case .Following:
//                    print(FeedFilter.Following)
//                }
//            }.padding(.trailing, 7.5)
        }
    }
}
