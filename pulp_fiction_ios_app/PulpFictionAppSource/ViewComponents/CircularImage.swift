//
//  CircularImage.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/16/22.
//

import Foundation
import SwiftUI

public struct CircularImage: View {
    let uiImage: UIImage
    let radius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat

    public var body: some View {
        uiImage
            .toImage()
            .resizable()
            .frame(width: 2 * radius, height: 2 * radius)
            .clipShape(Circle())
            .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
    }
}
