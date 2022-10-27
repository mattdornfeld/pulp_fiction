//
//  TopNavigationBar.swift
//  build_app
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import Foundation
import SwiftUI

protocol NavigationBarContents: View {}

struct TopNavigationBarView<TopNavigationBarViewContent: NavigationBarContents, MainViewContent: View>: View {
    let topNavigationBarViewBuilder: () -> TopNavigationBarViewContent
    @ViewBuilder let mainViewContentBuilder: () -> MainViewContent

    var body: some View {
        VStack(spacing: 8.0) {
            topNavigationBarViewBuilder()
            Divider()
            mainViewContentBuilder()
        }
    }
}
