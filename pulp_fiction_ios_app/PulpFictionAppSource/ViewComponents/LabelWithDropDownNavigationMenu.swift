//
//  LabelWithDropDownButtonMenu.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/15/22.
//

import Foundation
import SwiftUI

/// All menu options for LabelWithDropDownNavigationMenu should override this
protocol NavigationDropDownMenuOption: DropDownMenuOption {
    /// If true a NavigationLink will be created for this MenuOption
    var isNavigationOption: Bool { get }
}

/// Dropdown menu of navigation links
struct LabelWithDropDownNavigationMenu<Label: View, MenuOption: NavigationDropDownMenuOption, Destination: View>: View {
    /// Label that will be clicked to display dropdown menu
    let label: Label
    /// Array of options for the drop down menu
    let menuOptions: [MenuOption]
    /// Function that supplies the destination view for each MenuOption
    @ViewBuilder let destinationSupplier: (MenuOption) -> Destination
    /// Function that supplies the binding that signifies if the the navigation link is active and the action to perform when link is clicked
    let navigationAction: (MenuOption) -> (Binding<Bool>, () -> Void)

    var body: some View {
        Menu(content: {
            ForEach(menuOptions, id: \.self) { menuOption in
                let t2 = navigationAction(menuOption)
                Button(menuOption.rawValue, action: t2.1)
            }
        }) { label }

        /// The Menu view is outside of the NavigationView so we specified the NavigationLinks here and activate them with Buttons inside of the Menu
        ForEach(menuOptions, id: \.self) { menuOption in
            if menuOption.isNavigationOption {
                NavigationLink(
                    destination: destinationSupplier(menuOption)
                        .navigationBarBackButtonHidden(true)
                        .navigationBarItems(leading: BackButton()),
                    isActive: navigationAction(menuOption).0
                ) {
                    EmptyView()
                }
            }
        }
    }
}
