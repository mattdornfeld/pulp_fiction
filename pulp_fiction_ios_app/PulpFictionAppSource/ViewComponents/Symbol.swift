//
//  Symbol.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/19/22.
//

import Foundation
import SwiftUI

public struct Symbol: View {
    public let symbolName: String

    public var body: some View {
        Image(systemName: symbolName)
            .foregroundColor(.gray)
    }
}

public extension Symbol {
    init(_ symbolName: String) {
        self.init(symbolName: symbolName)
    }
}
