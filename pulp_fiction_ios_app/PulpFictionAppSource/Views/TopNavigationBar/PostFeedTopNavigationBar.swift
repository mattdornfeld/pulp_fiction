//
//  PostFeedTopNavigationBarView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

struct PostFeedTopNavigationBar: NavigationBarContents {
    let postFeedFilter: PostFeedFilter
    let dropDownMenuSelectionAction: (PostFeedFilter) -> Void

    var body: some View {
        HStack {
            Title("Pulp Fiction")
                .foregroundColor(.gray)
                .padding(.leading, 7.5)
            Spacer()
            Symbol(symbolName: "plus", size: 25, color: .gray)
            SymbolWithDropDownMenu(
                symbolName: "line.3.horizontal.decrease.circle",
                symbolSize: 25,
                symbolColor: .gray,
                menuOptions: PostFeedFilter.allCases,
                initialMenuSelection: postFeedFilter,
                dropDownMenuSelectionAction: dropDownMenuSelectionAction
            ).padding(.trailing, 7.5)
        }
    }
}
