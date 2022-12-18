//
//  CommentCreatoreTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/29/22.
//

import Foundation
import SwiftUI

/// Contents for the top navigation bar of a text creation view
struct TextCreatorTopNavigationBar: ToolbarContent {
    let createButtonLabel: String
    /// Function that's called when Post button is tapped
    let tapPostButtonAction: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationText(createButtonLabel)
                .font(.system(size: 25))
                .foregroundColor(.gray)
                .padding(.trailing, 5)
                .onTapGesture(perform: tapPostButtonAction)
        }
    }
}
