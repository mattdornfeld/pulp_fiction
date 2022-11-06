//
//  BackButton.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/06/22.
//

import Foundation
import SwiftUI

/// View that creates the back button for a NavigationLink
fileprivate struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body : some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.gray)
                .font(.title2)
        }
    }
}

public extension View {
    /// Navigates to destination when View is tapped
    /// - Parameters:
    ///   - isActive: binding that signifies whether NavigationLink is active
    ///   - destination: destionation View
    ///   - perform: a function to be executed when View is tapped
    /// - Returns: a NavigationLink that executes the navigation when View is tapped
    func navigateOnTap<Content: View>(
        isActive: Binding<Bool>,
        destination: @autoclosure @escaping () -> Content,
        perform: @escaping () -> Void
    ) -> some View {
        NavigationLink(
            isActive: isActive,
            destination: {
                LazyView(destination)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(leading: BackButton())
            },
            label: { self.onTapGesture(perform: perform) }
        )
    }
}
