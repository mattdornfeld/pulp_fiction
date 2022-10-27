//
//  UserConnectionsTopFeedNavigationBarContents.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

/// Top navigation bar view for the user connections page
struct UserConnectionsTopNavigationBar: NavigationBarContents {
    let userConnectionsFilter: UserConnectionsFilter
    let dropDownMenuSelectionAction: (UserConnectionsFilter) -> Void

    var body: some View {
        HStack {
            Title(userConnectionsFilter.rawValue)
                .foregroundColor(.gray)
                .padding(.leading, 7.5)
            Spacer()
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
