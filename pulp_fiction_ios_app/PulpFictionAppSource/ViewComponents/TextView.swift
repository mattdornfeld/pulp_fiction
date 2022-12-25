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
    init(text: String, alignment: TextAlignment, color: Color?) {
        self.text = Text(text)
            .font(.caption)
            .foregroundColor(color)
        self.alignment = alignment
    }

    init(text: String, color: Color) {
        self.init(text: text, alignment: .leading, color: color)
    }

    init(text: String, alignment: TextAlignment) {
        self.init(text: text, alignment: alignment, color: nil)
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading, color: nil)
    }
}

struct BoldCaption: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension BoldCaption {
    init(text: String, alignment: TextAlignment, color: Color?) {
        self.text = Text(text)
            .fontWeight(.bold)
            .font(.caption)
            .foregroundColor(color)
        self.alignment = alignment
    }

    init(text: String, color: Color) {
        self.init(text: text, alignment: .leading, color: color)
    }

    init(text: String, alignment: TextAlignment) {
        self.init(text: text, alignment: alignment, color: nil)
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading, color: nil)
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

struct NavigationText: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension NavigationText {
    init(text: String, alignment: TextAlignment, color: Color?) {
        self.text = Text(text).foregroundColor(color)
        self.alignment = alignment
    }

    init(text: String, alignment: TextAlignment) {
        self.init(text: text, alignment: alignment, color: nil)
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading, color: nil)
    }
}

struct HeadlineText: TextView {
    let text: Text
    let alignment: TextAlignment
}

extension HeadlineText {
    init(text: String, alignment: TextAlignment, color: Color?) {
        self.text = Text(text).font(.headline).foregroundColor(color)
        self.alignment = alignment
    }

    init(text: String, alignment: TextAlignment) {
        self.init(text: text, alignment: alignment, color: nil)
    }

    init(_ text: String) {
        self.init(text: text, alignment: .leading, color: nil)
    }
}
