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

    public var body: some View {
        HStack {
            Symbol(symbolName: symbolName)
            Caption(symbolCaption).foregroundColor(.gray)
        }
    }
}

public extension SymbolWithCaption {
    init(_ symbolName: String, _ symbolCaption: String) {
        self.init(symbolName: symbolName, symbolCaption: symbolCaption)
    }
}
