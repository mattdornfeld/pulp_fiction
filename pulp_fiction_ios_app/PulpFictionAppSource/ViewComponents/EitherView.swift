//
//  EitherView.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/11/22.
//

import Bow
import Foundation
import SwiftUI

public struct EitherView<A: View, B: View>: View {
    let state: Either<A, B>

    public var body: some View {
        switch state.toEnum() {
        case let .right(right):
            right
        case let .left(left):
            left
        }
    }
}
