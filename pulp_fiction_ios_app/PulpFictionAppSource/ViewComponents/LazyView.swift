//
//  LazyView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/13/22.
//

import Foundation
import SwiftUI

/// Class that loads a view lazily. Mostly useful for specifying the destination property on NavigationLink.
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    init(_ build: @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
