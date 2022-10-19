//
//  Caption.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Foundation
import SwiftUI

public protocol TextView: View {
    var text: Text { get }
}

public extension TextView {
    func append(textView: any TextView, delimiter: String = " ") -> GenericText {
        GenericText(text: text + Text(delimiter) + textView.text)
    }

    var body: some View {
        self.text
    }
}

public struct GenericText: TextView {
    public let text: Text
}

public struct Caption: TextView {
    public let text: Text

    public init(text: String) {
        self.text = Text(text).font(.caption)
    }
}

public extension Caption {
    init(_ text: String) {
        self.init(text: text)
    }
}

public struct BoldCaption: TextView {
    public let text: Text

    public init(text: String) {
        self.text = Text(text).fontWeight(.bold).font(.caption)
    }
}

public extension BoldCaption {
    init(_ text: String) {
        self.init(text: text)
    }
}
