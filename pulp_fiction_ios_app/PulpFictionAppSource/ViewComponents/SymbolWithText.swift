//
//  SymbolWithText.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/19/22.
//

import Foundation
import SwiftUI

public struct SymbolWithCaption: View {
    public let symbolName: String
    public let symbolCaption: String
    public let color: Color

    public var body: some View {
        HStack {
            Image(systemName: symbolName).foregroundStyle(color)
            Caption(
                text: symbolCaption,
                color: color
            )
        }
    }
}

public extension SymbolWithCaption {
    init(symbolName: String, symbolCaption: String) {
        self.init(symbolName: symbolName, symbolCaption: symbolCaption, color: .gray)
    }
}
