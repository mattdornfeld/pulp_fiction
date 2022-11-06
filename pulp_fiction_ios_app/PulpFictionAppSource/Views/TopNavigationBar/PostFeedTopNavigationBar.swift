//
//  PostFeedTopNavigationBarView.swift
//  build_app
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

struct PostFeedTopNavigationBar: ToolbarContent {
    let postFeedFilter: PostFeedFilter
    let dropDownMenuSelectionAction: (PostFeedFilter) -> Void

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
                )
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
