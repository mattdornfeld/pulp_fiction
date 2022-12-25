//
//  AvatarSelectorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/18/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct AvatarSelectorTopNavigationBar: ToolbarContent {
    let updateButtonAction: (Binding<PresentationMode>) -> Void
    let imageSourceTypeDropDownMenuView: SymbolWithDropDownMenuView<ImageSourceType>
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                imageSourceTypeDropDownMenuView
                NavigationText("Update")
                    .font(.system(size: 25))
                    .foregroundColor(.gray)
                    .padding(.trailing, 5)
                    .onTapGesture(perform: { updateButtonAction(presentationMode) })
            }
        }
    }
}

struct AvatarSelectorView: View {
    let updateButtonAction: (UIImage) -> Void
    @ObservedObject private var imageSourceTypeDropDownMenu: SymbolWithDropDownMenu<ImageSourceType> = .init(
        symbolName: "line.3.horizontal.decrease.circle",
        symbolSize: 20,
        symbolColor: .gray,
        menuOptions: ImageSourceType.allCases,
        initialMenuSelection: .Album
    )

    var body: some View {
        ImageSelectorView(
            topNavigationBarSupplier: { viewStore in
                AvatarSelectorTopNavigationBar(
                    updateButtonAction: { presentationMode in
                        viewStore.postUIImageMaybe.map { postUIImage in
                            updateButtonAction(postUIImage)
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    imageSourceTypeDropDownMenuView: imageSourceTypeDropDownMenu.view
                )
            },
            imageSourceType: imageSourceTypeDropDownMenu.currentSelection
        )
    }
}
