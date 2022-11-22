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
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationBarText("Update")
                .font(.system(size: 25))
                .foregroundColor(.gray)
                .padding(.trailing, 5)
                .onTapGesture(perform: { updateButtonAction(presentationMode) })
        }
    }
}

struct AvatarSelectorView: View {
    let updateButtonAction: (UIImage) -> Void

    var body: some View {
        ImageSelectorView(
            topNavigationBarSupplier: { viewStore in
                AvatarSelectorTopNavigationBar(
                    updateButtonAction: { presentationMode in
                        viewStore.postUIImageMaybe.map { postUIImage in
                            updateButtonAction(postUIImage)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        )
    }
}
