//
//  PulpFictionNavigationButton.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/31/22.
//

import Foundation
import SwiftUI

struct PulpFictionNavigationButton<Destination: View>: View {
    let text: String
    let backgroundColor: Color
    private let emptyNavigationLink: EmptyNavigationLink<Destination>

    init(text: String, backgroundColor: Color, destinationSupplier: @escaping () -> Destination) {
        self.text = text
        self.backgroundColor = backgroundColor
        emptyNavigationLink = .init(destinationSupplier: destinationSupplier)
    }

    var body: some View {
        VStack {
            emptyNavigationLink.view
            PulpFictionButton(
                text: text,
                backgroundColor: backgroundColor
            ) {
                emptyNavigationLink.viewStore.send(.navigateToDestionationView())
            }
        }
    }
}
