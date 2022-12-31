//
//  PulpFictionButton.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/31/22.
//

import Foundation
import SwiftUI

struct PulpFictionButton: View {
    let text: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HeadlineText(
                text: text,
                alignment: .center,
                color: .white
            )
            .padding()
            .frame(width: 220, height: 60)
            .background(backgroundColor)
            .cornerRadius(15.0)
        }
    }
}
