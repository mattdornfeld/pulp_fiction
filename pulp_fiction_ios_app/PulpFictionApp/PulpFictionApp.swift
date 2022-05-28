//
//  PictureSaverApp.swift
//  PictureSaver
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import SwiftUI

@main
struct PulpFictionApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VStack {
                    NavigationLink("create", destination: ContentView())
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView())
                }
            }
        }
    }
}
