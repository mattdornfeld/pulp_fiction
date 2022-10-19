//
//  ViewExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/13/22.
//

import Foundation
import SwiftUI

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
            destination: { LazyView(destination) },
            label: { self.onTapGesture(perform: perform) }
        )
    }
}
