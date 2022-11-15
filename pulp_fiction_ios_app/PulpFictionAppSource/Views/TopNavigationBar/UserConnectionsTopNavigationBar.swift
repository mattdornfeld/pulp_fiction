//
//  UserConnectionsTopFeedNavigationBarContents.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// Top navigation bar view for the user connections page
struct UserConnectionsTopNavigationBar: ToolbarContent {
    let userConnectionsFilter: UserConnectionsFilter
    let dropDownMenuSelectionAction: (UserConnectionsFilter) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title(userConnectionsFilter.rawValue)
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            SymbolWithDropDownMenu(
                symbolName: "line.3.horizontal.decrease.circle",
                symbolSize: 25,
                symbolColor: .gray,
                menuOptions: UserConnectionsFilter.allCases,
                initialMenuSelection: userConnectionsFilter,
                dropDownMenuSelectionAction: dropDownMenuSelectionAction
            ).padding(.trailing, 7.5)
        }
    }
}
