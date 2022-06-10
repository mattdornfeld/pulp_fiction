//
//  PictureSaverApp.swift
//  PictureSaver
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import ComposableArchitecture
import SwiftUI

@main
struct PulpFictionApp: App {
    var body: some Scene {
        // TODO: Add error handling here so error message is displayed to user if connection to database fails
        let localImageStore = LocalImageStore()!

        WindowGroup {
            NavigationView {
                VStack {
                    NavigationLink("create", destination: PostCreatorView(localImageStore: localImageStore))
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView(localImageStore: localImageStore))
                }
            }
        }
    }
}
