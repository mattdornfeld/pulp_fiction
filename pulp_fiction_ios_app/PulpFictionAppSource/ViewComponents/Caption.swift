//
//  Caption.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Foundation
import SwiftUI

public struct Caption: View {
    public let text: String
    
    public var body: some View {
        Text(text).font(.caption)
    }
}

public extension Caption {
    init(_ text: String) {
        self.init(text: text)
    }
}

public struct BoldCaption: View {
    public let text: String
    
    public var body: some View {
        Text(text).fontWeight(.bold).font(.caption)
    }
}

public extension BoldCaption {
    init(_ text: String) {
        self.init(text: text)
    }
}
