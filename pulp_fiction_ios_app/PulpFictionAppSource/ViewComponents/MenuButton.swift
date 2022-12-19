//
//  MenuButton.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/18/22.
//

import Foundation
import SwiftUI

/// View for creating buttons for menus
struct MenuButton: View {
    let text: String
    let backgroundColor: Color
    let action: () -> Void
    var body: some View {
        Button(
            action: action,
            label: {
                NavigationText(
                    text: text,
                    alignment: .center,
                    color: .white
                )
                .padding()
                .padding(.horizontal, 20)
                .background(backgroundColor)
                .cornerRadius(10)
            }
        )
    }
}
