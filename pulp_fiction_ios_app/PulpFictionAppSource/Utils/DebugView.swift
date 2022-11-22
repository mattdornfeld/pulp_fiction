//
//  DebugView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/21/22.
//

import Foundation
import SwiftUI

protocol DebugView: View {
    func viewPrint(_ msg: Any) -> EmptyView
}

extension DebugView {
    func viewPrint(_ msg: Any) -> EmptyView {
        print(msg)
        return EmptyView()
    }
}
