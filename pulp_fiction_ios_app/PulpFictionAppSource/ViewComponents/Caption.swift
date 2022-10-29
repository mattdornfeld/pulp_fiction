//
//  Caption.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Foundation
import SwiftUI

protocol TextView: View {
    var text: Text { get }
    var alignment: TextAlignment { get }
}

extension TextView {
    func append(textView: any TextView, delimiter: String = " ") -> GenericText {
        GenericText(text: text + Text(delimiter) + textView.text)
    }

    var body: some View {
        self.text.multilineTextAlignment(alignment)
    }
}

struct GenericText: TextView {
    let text: Text
    let alignment: TextAlignment = .leading
}

struct Caption: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension Caption {
    init(text: String, alignment: TextAlignment) {
        self.text = Text(text).font(.caption)
        self.alignment = alignment
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading)
    }
}

struct BoldCaption: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension BoldCaption {
    init(text: String, alignment: TextAlignment) {
        self.text = Text(text).fontWeight(.bold).font(.caption)
        self.alignment = alignment
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading)
    }
}

struct Title: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension Title {
    init(text: String, alignment: TextAlignment) {
        self.text = Text(text).font(.title).font(.caption)
        self.alignment = alignment
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading)
    }
}

struct NavigationBarText: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension NavigationBarText {
    init(text: String, alignment: TextAlignment) {
        self.text = Text(text)
        self.alignment = alignment
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading)
    }
}
