//
//  Symbol.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/19/22.
//

import Foundation
import SwiftUI

struct Symbol: View {
    let symbolName: String
    let size: CGFloat?
    let color: Color

    var body: some View {
        let image = Image(systemName: symbolName)
        
        size
            .toEither()
            .mapLeft{ _ in image }
            .mapRight { image
                .font(.system(size: $0))
            }
            .toEitherView()
            .foregroundColor(color)
    }
}

extension Symbol {
    init(symbolName: String) {
        self.init(symbolName: symbolName, size: nil, color: .gray)
    }
}

