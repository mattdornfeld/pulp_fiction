//
//  OnDragUp.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/11/22.
//

import Foundation
import SwiftUI

/// Adds a DragGesture to view that calls the handler function when view is dragged up
struct OnDragUp<A: View>: View {
    let view: A
    let handler: () -> Void
    private let refreshFeedOnScrollUpSensitivity: CGFloat = 10.0
    @GestureState private var dragOffset: CGFloat = -100

    var body: some View {
        view
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, gestureState, _ in
                        let delta = value.location.y - value.startLocation.y
                        if delta > refreshFeedOnScrollUpSensitivity {
                            gestureState = delta
                            handler()
                        }
                    }
            )
    }
}

extension View {
    func onDragUp(handler: @escaping () -> Void) -> some View {
        OnDragUp(view: self, handler: handler)
    }
}
